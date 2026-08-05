import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

// Defaults to dev mode unless explicitly disabled, so local/dev environments never
// accidentally fire real provider calls just because the env var is unset.
const isDevMode = () => process.env.SITE_OTP_DEV_MODE !== 'false';

@Injectable()
export class OtpDeliveryService {
  private readonly logger = new Logger(OtpDeliveryService.name);

  async sendWhatsApp(phone: string, otp: string): Promise<void> {
    if (isDevMode()) {
      console.log(`[OTP DEV] WhatsApp OTP for ${phone}: ${otp}`);
      return;
    }
    try {
      await fetch('https://api.msg91.com/api/v5/flow/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          authkey: process.env.MSG91_AUTH_KEY || '',
        },
        body: JSON.stringify({
          template_id: process.env.MSG91_WHATSAPP_TEMPLATE_ID,
          mobile: phone,
          otp,
        }),
      });
    } catch (err) {
      this.logger.error(`Failed to send WhatsApp OTP to ${phone}: ${err}`);
    }
  }

  async sendEmail(email: string, otp: string): Promise<void> {
    if (isDevMode()) {
      console.log(`[OTP DEV] Email OTP for ${email}: ${otp}`);
      return;
    }
    if (!process.env.SMTP_HOST) {
      console.log(`[OTP] SMTP not configured, OTP for ${email}: ${otp}`);
      return;
    }
    try {
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: Number(process.env.SMTP_PORT) || 587,
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        },
      });
      await transporter.sendMail({
        from: process.env.SMTP_USER,
        to: email,
        subject: 'Your OTP code',
        text: `Your OTP code is ${otp}. It expires in 5 minutes.`,
      });
    } catch (err) {
      this.logger.error(`Failed to send email OTP to ${email}: ${err}`);
    }
  }
}
