import { Request, Response } from 'express';
import { RouteModel } from '../models/Route';
import { CreateRouteRequest, ApiResponse } from '../types';

export class RouteController {
    // POST /routes
    static async create(req: any, res: Response): Promise<void> {
        try {
            const routeData: CreateRouteRequest = req.body;
            const route = await RouteModel.create(req.user.id, routeData);

            res.status(201).json({
                status: 'success',
                message: 'Route created successfully',
                data: {
                    route_id: route.id,
                    route
                }
            } as ApiResponse);
        } catch (error) {
            console.error('Create route error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to create route'
            } as ApiResponse);
        }
    }

    // GET /routes
    static async getAll(req: any, res: Response): Promise<void> {
        try {
            const routes = await RouteModel.findByUserId(req.user.id);

            res.status(200).json({
                status: 'success',
                data: routes
            } as ApiResponse);
        } catch (error) {
            console.error('Get routes error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to get routes'
            } as ApiResponse);
        }
    }

    // GET /routes/:id
    static async getById(req: any, res: Response): Promise<void> {
        try {
            const { id } = req.params;
            const route = await RouteModel.findById(id);

            if (!route || route.user_id !== req.user.id) {
                res.status(404).json({
                    status: 'error',
                    message: 'Route not found'
                } as ApiResponse);
                return;
            }

            res.status(200).json({
                status: 'success',
                data: route
            } as ApiResponse);
        } catch (error) {
            console.error('Get route error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to get route'
            } as ApiResponse);
        }
    }

    // PUT /routes/:id
    static async update(req: any, res: Response): Promise<void> {
        try {
            const { id } = req.params;
            const updates = req.body;

            const existingRoute = await RouteModel.findById(id);

            if (!existingRoute || existingRoute.user_id !== req.user.id) {
                res.status(404).json({
                    status: 'error',
                    message: 'Route not found'
                } as ApiResponse);
                return;
            }

            const route = await RouteModel.update(id, updates);

            res.status(200).json({
                status: 'success',
                message: 'Route updated successfully',
                data: route
            } as ApiResponse);
        } catch (error) {
            console.error('Update route error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to update route'
            } as ApiResponse);
        }
    }

    // DELETE /routes/:id
    static async delete(req: any, res: Response): Promise<void> {
        try {
            const { id } = req.params;

            const route = await RouteModel.findById(id);

            if (!route || route.user_id !== req.user.id) {
                res.status(404).json({
                    status: 'error',
                    message: 'Route not found'
                } as ApiResponse);
                return;
            }

            await RouteModel.delete(id);

            res.status(200).json({
                status: 'success',
                message: 'Route deleted successfully'
            } as ApiResponse);
        } catch (error) {
            console.error('Delete route error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to delete route'
            } as ApiResponse);
        }
    }

    // PATCH /routes/:id/toggle
    static async toggleActive(req: any, res: Response): Promise<void> {
        try {
            const { id } = req.params;
            const { is_active } = req.body;

            const existingRoute = await RouteModel.findById(id);

            if (!existingRoute || existingRoute.user_id !== req.user.id) {
                res.status(404).json({
                    status: 'error',
                    message: 'Route not found'
                } as ApiResponse);
                return;
            }

            const route = await RouteModel.toggleActive(id, is_active);

            res.status(200).json({
                status: 'success',
                message: `Route ${is_active ? 'activated' : 'deactivated'} successfully`,
                data: route
            } as ApiResponse);
        } catch (error) {
            console.error('Toggle route error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to toggle route'
            } as ApiResponse);
        }
    }
}
