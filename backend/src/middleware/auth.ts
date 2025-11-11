import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt';
import { UserModel } from '../models/User';

export interface AuthRequest extends Request {
    user?: {
        id: string;
        phone_number: string;
    };
}

export const authenticate = async (
    req: AuthRequest,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({
                status: 'error',
                message: 'No token provided'
            });
            return;
        }

        const token = authHeader.substring(7);
        const decoded = verifyToken(token);

        if (!decoded) {
            res.status(401).json({
                status: 'error',
                message: 'Invalid or expired token'
            });
            return;
        }

        // Verify user exists and is active
        const user = await UserModel.findById(decoded.user_id);

        if (!user || !user.is_active) {
            res.status(401).json({
                status: 'error',
                message: 'User not found or inactive'
            });
            return;
        }

        req.user = {
            id: decoded.user_id,
            phone_number: decoded.phone_number
        };

        next();
    } catch (error) {
        console.error('Authentication error:', error);
        res.status(500).json({
            status: 'error',
            message: 'Authentication failed'
        });
    }
};

export const optionalAuth = async (
    req: AuthRequest,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const authHeader = req.headers.authorization;

        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.substring(7);
            const decoded = verifyToken(token);

            if (decoded) {
                req.user = {
                    id: decoded.user_id,
                    phone_number: decoded.phone_number
                };
            }
        }

        next();
    } catch (error) {
        next();
    }
};
