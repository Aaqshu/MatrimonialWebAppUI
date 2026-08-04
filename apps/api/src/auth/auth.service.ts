import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuthService {
  constructor(private db: PrismaService, private jwt: JwtService) {}

  async login(userName: string, password: string) {
    const { rows } = await this.db.query('SELECT * FROM "AdminUsers" WHERE "AdminUserName" = $1', [userName]);
    if (!rows.length) throw new UnauthorizedException('Invalid credentials');
    const user = rows[0];
    const valid = user.Password ? await bcrypt.compare(password, user.Password) : false;
    if (!valid) throw new UnauthorizedException('Invalid credentials');
    const payload = { sub: user.AdminId, userName: user.AdminUserName, role: user.Role };
    return { access_token: this.jwt.sign(payload) };
  }
}
