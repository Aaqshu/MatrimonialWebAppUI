import { BadRequestException, Body, Controller, Get, Headers, Param, Post, Query, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomUUID as uuid } from 'crypto';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

// Messaging: only between users with an ACCEPTED mutual interest (a match).
// Polling-based (no websocket provider needed for v1).

@Public()
@Controller('site/messages')
export class SiteMessagesController {
  constructor(
    private tenantDb: TenantDbService,
    private jwt: JwtService,
  ) {}

  private auth(headers: any): { sub: string } {
    const authz: string = headers['authorization'] || '';
    if (!authz.startsWith('Bearer ')) throw new UnauthorizedException('Missing bearer token');
    try {
      return this.jwt.verify(authz.slice(7));
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  // Must be a mutual match: I accepted theirs OR they accepted mine
  private async isMatched(db: any, me: string, other: string): Promise<boolean> {
    const { rows } = await db.query(
      `SELECT 1 FROM "InterestRequests"
       WHERE (("SenderUserId" = $1 AND "ReceiverUserId" = $2) OR ("SenderUserId" = $2 AND "ReceiverUserId" = $1))
         AND "Status" = 'accepted'`,
      [me, other],
    );
    return rows.length > 0;
  }

  @Post(':tenantDbName')
  async send(@Param('tenantDbName') tenantDbName: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const toUserId = body?.toUserId;
    const message = body?.message;
    if (!toUserId) throw new BadRequestException('toUserId required');
    if (!message || !String(message).trim()) throw new BadRequestException('message required');
    if (toUserId === sub) throw new BadRequestException('Cannot message yourself');
    if (String(message).length > 2000) throw new BadRequestException('Message too long (max 2000 chars)');

    const db = this.tenantDb.getDb(tenantDbName);

    const blocked = (await db.query(
      `SELECT 1 FROM "BlockedUsers" WHERE "UserId" = $1 AND "BlockedUserId" = $2`,
      [sub, toUserId],
    )).rows[0];
    if (blocked) throw new BadRequestException('Cannot message this user');

    if (!(await this.isMatched(db, sub, toUserId))) {
      throw new BadRequestException('You can only message accepted matches');
    }

    const { rows } = await db.query(
      `INSERT INTO "Messages" ("MessageId","SenderUserId","ReceiverUserId","Message")
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [uuid(), sub, toUserId, String(message).trim()],
    );

    // notification for receiver
    const senderName = (await db.query(`SELECT "FirstName" FROM "Users" WHERE "UserId" = $1`, [sub])).rows[0]?.FirstName || 'Someone';
    await db.query(
      `INSERT INTO "Notifications" ("NotificationId","UserId","Title","Message")
       VALUES ($1,$2,$3,$4)`,
      [uuid(), toUserId, 'New message', `${senderName} sent you a message`],
    );

    return { message: rows[0] };
  }

  @Get(':tenantDbName/threads')
  async threads(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);

    // distinct conversation partners + last message + unread count
    const { rows } = await db.query(
      `SELECT
         other."UserId" AS "UserId", u."FirstName", u."LastName", l."City",
         (SELECT ph."PhotoUrl" FROM "UserPhotos" ph WHERE ph."UserId" = other."UserId" AND ph."IsPrimary" = TRUE LIMIT 1) AS "PhotoUrl",
         (SELECT m."Message" FROM "Messages" m WHERE (m."SenderUserId" = $1 AND m."ReceiverUserId" = other."UserId") OR (m."SenderUserId" = other."UserId" AND m."ReceiverUserId" = $1) ORDER BY m."SentOn" DESC LIMIT 1) AS "LastMessage",
         (SELECT m."SentOn" FROM "Messages" m WHERE (m."SenderUserId" = $1 AND m."ReceiverUserId" = other."UserId") OR (m."SenderUserId" = other."UserId" AND m."ReceiverUserId" = $1) ORDER BY m."SentOn" DESC LIMIT 1) AS "LastSentOn",
         (SELECT COUNT(*) FROM "Messages" m WHERE m."SenderUserId" = other."UserId" AND m."ReceiverUserId" = $1 AND m."IsRead" = FALSE)::int AS "UnreadCount"
       FROM (
         SELECT DISTINCT CASE WHEN "SenderUserId" = $1 THEN "ReceiverUserId" ELSE "SenderUserId" END AS "UserId"
         FROM "Messages" WHERE "SenderUserId" = $1 OR "ReceiverUserId" = $1
       ) other
       JOIN "Users" u ON u."UserId" = other."UserId"
       LEFT JOIN "UserLocation" l ON l."UserId" = u."UserId"
       ORDER BY "LastSentOn" DESC NULLS LAST`,
      [sub],
    );
    return { threads: rows };
  }

  @Get(':tenantDbName/:userId')
  async conversation(
    @Param('tenantDbName') tenantDbName: string,
    @Param('userId') userId: string,
    @Query('after') after: string | undefined,
    @Headers() headers: any,
  ) {
    const { sub } = this.auth(headers);
    if (userId === sub) throw new BadRequestException('Invalid conversation');
    const db = this.tenantDb.getDb(tenantDbName);

    const afterTs = after ? new Date(after) : null;
    const { rows } = await db.query(
      `SELECT "MessageId","SenderUserId","ReceiverUserId","Message","IsRead","SentOn"
       FROM "Messages"
       WHERE (("SenderUserId" = $1 AND "ReceiverUserId" = $2) OR ("SenderUserId" = $2 AND "ReceiverUserId" = $1))
         AND ($3::timestamptz IS NULL OR "SentOn" > $3)
       ORDER BY "SentOn" ASC
       LIMIT 200`,
      [sub, userId, afterTs],
    );

    // mark incoming as read
    await db.query(
      `UPDATE "Messages" SET "IsRead" = TRUE WHERE "SenderUserId" = $1 AND "ReceiverUserId" = $2 AND "IsRead" = FALSE`,
      [userId, sub],
    );

    return { messages: rows };
  }
}
