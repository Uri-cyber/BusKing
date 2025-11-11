import { query } from '../config/database';
import { ChecklistItem } from '../types';

export class ChecklistModel {
    static async getDefaultItems(): Promise<ChecklistItem[]> {
        const result = await query(
            'SELECT * FROM checklist_items WHERE user_id IS NULL AND is_default = true ORDER BY display_order'
        );
        return result.rows;
    }

    static async getUserItems(user_id: string): Promise<ChecklistItem[]> {
        const result = await query(
            'SELECT * FROM checklist_items WHERE user_id = $1 AND is_active = true ORDER BY display_order',
            [user_id]
        );
        return result.rows;
    }

    static async getAllItems(user_id: string): Promise<ChecklistItem[]> {
        const result = await query(
            `SELECT * FROM checklist_items
             WHERE (user_id IS NULL AND is_default = true)
             OR (user_id = $1 AND is_active = true)
             ORDER BY display_order`,
            [user_id]
        );
        return result.rows;
    }

    static async create(user_id: string, item_name: string, emoji?: string, context?: string): Promise<ChecklistItem> {
        const result = await query(
            `INSERT INTO checklist_items (user_id, item_name, emoji, context, is_default)
             VALUES ($1, $2, $3, $4, false)
             RETURNING *`,
            [user_id, item_name, emoji, context]
        );
        return result.rows[0];
    }

    static async delete(id: string, user_id: string): Promise<void> {
        await query(
            'DELETE FROM checklist_items WHERE id = $1 AND user_id = $2',
            [id, user_id]
        );
    }

    static async updateOrder(id: string, user_id: string, new_order: number): Promise<ChecklistItem> {
        const result = await query(
            'UPDATE checklist_items SET display_order = $1 WHERE id = $2 AND user_id = $3 RETURNING *',
            [new_order, id, user_id]
        );
        return result.rows[0];
    }

    // Get contextual checklist based on weather and time
    static async getContextualChecklist(user_id: string, context: {
        isRainy?: boolean;
        isHot?: boolean;
        isCold?: boolean;
        isMorning?: boolean;
        isEvening?: boolean;
    }): Promise<ChecklistItem[]> {
        const conditions: string[] = ['always'];

        if (context.isRainy) conditions.push('rainy');
        if (context.isHot) conditions.push('hot');
        if (context.isCold) conditions.push('cold');
        if (context.isMorning) conditions.push('morning');
        if (context.isEvening) conditions.push('evening');

        const result = await query(
            `SELECT * FROM checklist_items
             WHERE ((user_id IS NULL AND is_default = true) OR (user_id = $1 AND is_active = true))
             AND (context = ANY($2) OR context IS NULL)
             ORDER BY display_order`,
            [user_id, conditions]
        );
        return result.rows;
    }
}
