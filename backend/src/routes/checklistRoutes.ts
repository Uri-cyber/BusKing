import { Router } from 'express';
import { ChecklistController } from '../controllers/checklistController';
import { authenticate } from '../middleware/auth';
import { createChecklistItemValidation, validate } from '../middleware/validation';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/v1/checklist
router.get('/', ChecklistController.getAll);

// GET /api/v1/checklist/contextual
router.get('/contextual', ChecklistController.getContextual);

// POST /api/v1/checklist
router.post('/', createChecklistItemValidation, validate, ChecklistController.create);

// DELETE /api/v1/checklist/:id
router.delete('/:id', ChecklistController.delete);

// PATCH /api/v1/checklist/:id/order
router.patch('/:id/order', ChecklistController.updateOrder);

export default router;
