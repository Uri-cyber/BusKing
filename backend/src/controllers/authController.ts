import { Request, Response } from 'express';
import { UserModel } from '../models/User';
import { generateVerificationCode, sendVerificationSMS, saveVerificationCode, verifyCode } from '../utils/sms';
import { generateToken } from '../utils/jwt';
import { RegisterRequest, VerifyRequest, ApiResponse, AuthResponse } from '../types';

export class AuthController {
    // POST /auth/register
    static async register(req: Request, res: Response): Promise<void> {
        try {
            const { phone_number, name }: RegisterRequest = req.body;

            // Check if user already exists
            let user = await UserModel.findByPhoneNumber(phone_number);

            if (!user) {
                user = await UserModel.create(phone_number, name);
            }

            // Generate and send verification code
            const code = generateVerificationCode();
            await saveVerificationCode(phone_number, code);
            await sendVerificationSMS(phone_number, code);

            res.status(200).json({
                status: 'success',
                message: 'Verification code sent via SMS',
                data: {
                    user_id: user.id
                }
            } as ApiResponse);
        } catch (error) {
            console.error('Register error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to register user'
            } as ApiResponse);
        }
    }

    // POST /auth/verify
    static async verify(req: Request, res: Response): Promise<void> {
        try {
            const { phone_number, code }: VerifyRequest = req.body;

            const isValid = await verifyCode(phone_number, code);

            if (!isValid) {
                res.status(400).json({
                    status: 'error',
                    message: 'Invalid or expired verification code'
                } as ApiResponse);
                return;
            }

            const user = await UserModel.findByPhoneNumber(phone_number);

            if (!user) {
                res.status(404).json({
                    status: 'error',
                    message: 'User not found'
                } as ApiResponse);
                return;
            }

            // Update last login
            await UserModel.updateLastLogin(user.id);

            // Generate JWT token
            const token = generateToken({
                user_id: user.id,
                phone_number: user.phone_number
            });

            res.status(200).json({
                status: 'success',
                data: {
                    token,
                    user: {
                        id: user.id,
                        name: user.name,
                        phone_number: user.phone_number,
                        settings: user.settings
                    }
                }
            } as ApiResponse<AuthResponse>);
        } catch (error) {
            console.error('Verify error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to verify code'
            } as ApiResponse);
        }
    }

    // GET /auth/me
    static async getProfile(req: any, res: Response): Promise<void> {
        try {
            const user = await UserModel.findById(req.user.id);

            if (!user) {
                res.status(404).json({
                    status: 'error',
                    message: 'User not found'
                } as ApiResponse);
                return;
            }

            res.status(200).json({
                status: 'success',
                data: {
                    id: user.id,
                    phone_number: user.phone_number,
                    name: user.name,
                    settings: user.settings,
                    created_at: user.created_at
                }
            } as ApiResponse);
        } catch (error) {
            console.error('Get profile error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to get user profile'
            } as ApiResponse);
        }
    }

    // PUT /auth/settings
    static async updateSettings(req: any, res: Response): Promise<void> {
        try {
            const updates = req.body;
            const user = await UserModel.updateSettings(req.user.id, updates);

            res.status(200).json({
                status: 'success',
                message: 'Settings updated successfully',
                data: {
                    settings: user.settings
                }
            } as ApiResponse);
        } catch (error) {
            console.error('Update settings error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Failed to update settings'
            } as ApiResponse);
        }
    }
}
