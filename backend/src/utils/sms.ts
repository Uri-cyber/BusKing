import twilio from 'twilio';
import { query } from '../config/database';
import dotenv from 'dotenv';

dotenv.config();

const twilioClient = twilio(
    process.env.TWILIO_ACCOUNT_SID,
    process.env.TWILIO_AUTH_TOKEN
);

const TWILIO_PHONE_NUMBER = process.env.TWILIO_PHONE_NUMBER;

export const generateVerificationCode = (): string => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

export const sendVerificationSMS = async (phone_number: string, code: string): Promise<void> => {
    try {
        if (process.env.NODE_ENV === 'development') {
            console.log(`📱 SMS Verification Code for ${phone_number}: ${code}`);
            return;
        }

        await twilioClient.messages.create({
            body: `BusAlert - קוד האימות שלך: ${code}\nהקוד תקף ל-10 דקות.`,
            from: TWILIO_PHONE_NUMBER,
            to: phone_number
        });

        console.log(`✅ Verification SMS sent to ${phone_number}`);
    } catch (error) {
        console.error('Error sending SMS:', error);
        throw new Error('Failed to send verification SMS');
    }
};

export const saveVerificationCode = async (phone_number: string, code: string): Promise<void> => {
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await query(
        `INSERT INTO verification_codes (phone_number, code, expires_at)
         VALUES ($1, $2, $3)`,
        [phone_number, code, expiresAt]
    );
};

export const verifyCode = async (phone_number: string, code: string): Promise<boolean> => {
    const result = await query(
        `SELECT * FROM verification_codes
         WHERE phone_number = $1
         AND code = $2
         AND is_used = false
         AND expires_at > NOW()
         ORDER BY created_at DESC
         LIMIT 1`,
        [phone_number, code]
    );

    if (result.rows.length === 0) {
        // Increment failed attempts
        await query(
            `UPDATE verification_codes
             SET attempts = attempts + 1
             WHERE phone_number = $1 AND code = $2`,
            [phone_number, code]
        );
        return false;
    }

    // Mark as used
    await query(
        `UPDATE verification_codes
         SET is_used = true
         WHERE phone_number = $1 AND code = $2`,
        [phone_number, code]
    );

    return true;
};
