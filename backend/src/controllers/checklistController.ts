import { Request, Response } from 'express';
import { ChecklistModel } from '../models/Checklist';
import { CreateChecklistItemRequest, ApiResponse } from '../types';

export class ChecklistController {
    // GET /checklist
    static async getAll(req: any, res: Response): Promise<void> {
        try {
            const items = await ChecklistModel.getAllItems(req.user.id);

            res.status(200).json({
                status: 'success',
                data: items
            } as ApiResponse);
        } catch (error) {
            console.error('Get checklist error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to get checklist items'
            } as ApiResponse);
        }
    }

    // GET /checklist/contextual
    static async getContextual(req: any, res: Response): Promise<void> {
        try {
            const { weather, time } = req.query;

            // Parse context from query params
            const context = {
                isRainy: weather === 'rainy',
                isHot: weather === 'hot',
                isCold: weather === 'cold',
                isMorning: time === 'morning',
                isEvening: time === 'evening'
            };

            const items = await ChecklistModel.getContextualChecklist(req.user.id, context);

            res.status(200).json({
                status: 'success',
                data: items
            } as ApiResponse);
        } catch (error) {
            console.error('Get contextual checklist error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to get contextual checklist'
            } as ApiResponse);
        }
    }

    // POST /checklist
    static async create(req: any, res: Response): Promise<void> {
        try {
            const { item_name, emoji, context }: CreateChecklistItemRequest = req.body;

            const item = await ChecklistModel.create(req.user.id, item_name, emoji, context);

            res.status(201).json({
                status: 'success',
                message: 'Checklist item created successfully',
                data: item
            } as ApiResponse);
        } catch (error) {
            console.error('Create checklist item error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to create checklist item'
            } as ApiResponse);
        }
    }

    // DELETE /checklist/:id
    static async delete(req: any, res: Response): Promise<void> {
        try {
            const { id } = req.params;

            await ChecklistModel.delete(id, req.user.id);

            res.status(200).json({
                status: 'success',
                message: 'Checklist item deleted successfully'
            } as ApiResponse);
        } catch (error) {
            console.error('Delete checklist item error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to delete checklist item'
            } as ApiResponse);
        }
    }

    // PATCH /checklist/:id/order
    static async updateOrder(req: any, res: Response): Promise<void> {
        try {
            const { id } = req.params;
            const { new_order } = req.body;

            const item = await ChecklistModel.updateOrder(id, req.user.id, new_order);

            res.status(200).json({
                status: 'success',
                message: 'Checklist order updated successfully',
                data: item
            } as ApiResponse);
        } catch (error) {
            console.error('Update checklist order error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to update checklist order'
            } as ApiResponse);
        }
    }
}
