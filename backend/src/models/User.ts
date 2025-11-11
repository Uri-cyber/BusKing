import { query } from '../config/database';
import { User, UserSettings } from '../types';

export class UserModel {
    static async create(phone_number: string, name?: string): Promise<User> {
        const result = await query(
            `INSERT INTO users (phone_number, name)
             VALUES ($1, $2)
             RETURNING *`,
            [phone_number, name]
        );
        return result.rows[0];
    }

    static async findByPhoneNumber(phone_number: string): Promise<User | null> {
        const result = await query(
            'SELECT * FROM users WHERE phone_number = $1',
            [phone_number]
        );
        return result.rows[0] || null;
    }

    static async findById(id: string): Promise<User | null> {
        const result = await query(
            'SELECT * FROM users WHERE id = $1',
            [id]
        );
        return result.rows[0] || null;
    }

    static async updateSettings(user_id: string, settings: Partial<UserSettings>): Promise<User> {
        const result = await query(
            `UPDATE users
             SET settings = settings || $1::jsonb
             WHERE id = $2
             RETURNING *`,
            [JSON.stringify(settings), user_id]
        );
        return result.rows[0];
    }

    static async updateLastLogin(user_id: string): Promise<void> {
        await query(
            'UPDATE users SET last_login = NOW() WHERE id = $1',
            [user_id]
        );
    }

    static async deactivate(user_id: string): Promise<void> {
        await query(
            'UPDATE users SET is_active = false WHERE id = $1',
            [user_id]
        );
    }
}
