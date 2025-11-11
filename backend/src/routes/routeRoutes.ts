import { Router } from 'express';
import { RouteController } from '../controllers/routeController';
import { authenticate } from '../middleware/auth';
import { createRouteValidation, validate } from '../middleware/validation';

const router = Router();

// All routes require authentication
router.use(authenticate);

// POST /api/v1/routes
router.post('/', createRouteValidation, validate, RouteController.create);

// GET /api/v1/routes
router.get('/', RouteController.getAll);

// GET /api/v1/routes/:id
router.get('/:id', RouteController.getById);

// PUT /api/v1/routes/:id
router.put('/:id', RouteController.update);

// DELETE /api/v1/routes/:id
router.delete('/:id', RouteController.delete);

// PATCH /api/v1/routes/:id/toggle
router.patch('/:id/toggle', RouteController.toggleActive);

export default router;
