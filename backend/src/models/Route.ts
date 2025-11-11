import { query } from '../config/database';
import { UserRoute, CreateRouteRequest } from '../types';

export class RouteModel {
    static async create(user_id: string, routeData: CreateRouteRequest): Promise<UserRoute> {
        const result = await query(
            `INSERT INTO user_routes
             (user_id, stop_id, stop_name, route_number, route_name,
              days_of_week, time_window_start, time_window_end, alert_minutes_before)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
             RETURNING *`,
            [
                user_id,
                routeData.stop_id,
                routeData.stop_name,
                routeData.route_number,
                routeData.route_name,
                routeData.days_of_week,
                routeData.time_window_start,
                routeData.time_window_end,
                routeData.alert_minutes_before || 5
            ]
        );
        return result.rows[0];
    }

    static async findByUserId(user_id: string): Promise<UserRoute[]> {
        const result = await query(
            'SELECT * FROM user_routes WHERE user_id = $1 AND is_active = true ORDER BY created_at DESC',
            [user_id]
        );
        return result.rows;
    }

    static async findById(id: string): Promise<UserRoute | null> {
        const result = await query(
            'SELECT * FROM user_routes WHERE id = $1',
            [id]
        );
        return result.rows[0] || null;
    }

    static async update(id: string, updates: Partial<UserRoute>): Promise<UserRoute> {
        const fields = Object.keys(updates);
        const values = Object.values(updates);
        const setClause = fields.map((field, idx) => `${field} = $${idx + 1}`).join(', ');

        const result = await query(
            `UPDATE user_routes SET ${setClause} WHERE id = $${fields.length + 1} RETURNING *`,
            [...values, id]
        );
        return result.rows[0];
    }

    static async delete(id: string): Promise<void> {
        await query('DELETE FROM user_routes WHERE id = $1', [id]);
    }

    static async toggleActive(id: string, is_active: boolean): Promise<UserRoute> {
        const result = await query(
            'UPDATE user_routes SET is_active = $1 WHERE id = $2 RETURNING *',
            [is_active, id]
        );
        return result.rows[0];
    }

    // Find routes that should be tracked now
    static async findActiveRoutes(currentDay: number, currentTime: string): Promise<UserRoute[]> {
        const result = await query(
            `SELECT ur.*, u.phone_number, u.settings
             FROM user_routes ur
             JOIN users u ON ur.user_id = u.id
             WHERE ur.is_active = true
             AND u.is_active = true
             AND $1 = ANY(ur.days_of_week)
             AND ur.time_window_start <= $2
             AND ur.time_window_end >= $2`,
            [currentDay, currentTime]
        );
        return result.rows;
    }
}
