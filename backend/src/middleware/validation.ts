import { Request, Response, NextFunction } from 'express';
import { validationResult, body } from 'express-validator';

export const validate = (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            status: 'error',
            message: 'Validation failed',
            errors: errors.array()
        });
    }
    next();
};

// Validation rules
export const registerValidation = [
    body('phone_number')
        .matches(/^\+972[0-9]{9}$/)
        .withMessage('Invalid Israeli phone number format (+972XXXXXXXXX)'),
    body('name')
        .optional()
        .trim()
        .isLength({ min: 2, max: 100 })
        .withMessage('Name must be between 2-100 characters')
];

export const verifyValidation = [
    body('phone_number')
        .matches(/^\+972[0-9]{9}$/)
        .withMessage('Invalid phone number'),
    body('code')
        .isLength({ min: 6, max: 6 })
        .isNumeric()
        .withMessage('Verification code must be 6 digits')
];

export const createRouteValidation = [
    body('stop_id')
        .notEmpty()
        .withMessage('Stop ID is required'),
    body('route_number')
        .notEmpty()
        .withMessage('Route number is required'),
    body('days_of_week')
        .isArray({ min: 1 })
        .withMessage('At least one day must be selected'),
    body('days_of_week.*')
        .isInt({ min: 0, max: 6 })
        .withMessage('Invalid day of week'),
    body('time_window_start')
        .matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
        .withMessage('Invalid time format (HH:MM)'),
    body('time_window_end')
        .matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
        .withMessage('Invalid time format (HH:MM)'),
    body('alert_minutes_before')
        .optional()
        .isInt({ min: 1, max: 60 })
        .withMessage('Alert minutes must be between 1-60')
];

export const createChecklistItemValidation = [
    body('item_name')
        .trim()
        .notEmpty()
        .isLength({ min: 2, max: 100 })
        .withMessage('Item name must be between 2-100 characters'),
    body('emoji')
        .optional(),
    body('context')
        .optional()
        .isIn(['always', 'morning', 'evening', 'rainy', 'hot', 'cold'])
        .withMessage('Invalid context')
];

export const startTrackingValidation = [
    body('stop_id')
        .notEmpty()
        .withMessage('Stop ID is required'),
    body('route_number')
        .notEmpty()
        .withMessage('Route number is required')
];
