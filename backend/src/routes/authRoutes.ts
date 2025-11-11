import { Router } from 'express';
import { AuthController } from '../controllers/authController';
import { authenticate } from '../middleware/auth';
import { registerValidation, verifyValidation, validate } from '../middleware/validation';

const router = Router();

// POST /api/v1/auth/register
router.post('/register', registerValidation, validate, AuthController.register);

// POST /api/v1/auth/verify
router.post('/verify', verifyValidation, validate, AuthController.verify);

// GET /api/v1/auth/me
router.get('/me', authenticate, AuthController.getProfile);

// PUT /api/v1/auth/settings
router.put('/settings', authenticate, AuthController.updateSettings);

export default router;
