import cron from 'node-cron';
import { RouteModel } from '../models/Route';
import { AlertEngine } from './alertEngine';
import logger from '../config/logger';

export class TrackingService {
    private static isRunning = false;
    private static cronJob: cron.ScheduledTask | null = null;

    /**
     * Start the tracking service (runs every 20 seconds)
     */
    static start(): void {
        if (this.isRunning) {
            logger.warn('Tracking service already running');
            return;
        }

        logger.info('🚀 Starting tracking service...');

        // Run every 20 seconds
        this.cronJob = cron.schedule('*/20 * * * * *', async () => {
            await this.checkActiveRoutes();
        });

        this.isRunning = true;
        logger.info('✅ Tracking service started');
    }

    /**
     * Stop the tracking service
     */
    static stop(): void {
        if (this.cronJob) {
            this.cronJob.stop();
            this.isRunning = false;
            logger.info('⏹ Tracking service stopped');
        }
    }

    /**
     * Check all active routes and send alerts
     */
    private static async checkActiveRoutes(): Promise<void> {
        try {
            const now = new Date();
            const currentDay = now.getDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
            const currentTime = now.toTimeString().substring(0, 5); // HH:MM

            // Get all routes that should be tracked now
            const activeRoutes = await RouteModel.findActiveRoutes(currentDay, currentTime);

            if (activeRoutes.length === 0) {
                return;
            }

            logger.info(`Checking ${activeRoutes.length} active routes`);

            // Process each route
            for (const route of activeRoutes) {
                try {
                    const user_phone = route.phone_number || route.whatsapp_number;

                    if (!user_phone) {
                        logger.warn(`No phone number for user ${route.user_id}`);
                        continue;
                    }

                    // Check if user is in quiet mode
                    const settings = route.settings;
                    if (this.isQuietMode(settings)) {
                        logger.info(`User ${route.user_id} in quiet mode, skipping`);
                        continue;
                    }

                    // Send alerts
                    await AlertEngine.checkAndSendAlerts(route, user_phone);
                } catch (error) {
                    logger.error(`Error processing route ${route.id}:`, error);
                }
            }
        } catch (error) {
            logger.error('Error checking active routes:', error);
        }
    }

    /**
     * Check if user is in quiet mode
     */
    private static isQuietMode(settings: any): boolean {
        if (!settings || !settings.quiet_mode) {
            return false;
        }

        const now = new Date();
        const currentHour = now.getHours();
        const currentMinute = now.getMinutes();
        const currentTime = currentHour * 60 + currentMinute;

        const [startHour, startMinute] = (settings.quiet_hours?.[0] || '22:00').split(':').map(Number);
        const [endHour, endMinute] = (settings.quiet_hours?.[1] || '06:00').split(':').map(Number);

        const quietStart = startHour * 60 + startMinute;
        const quietEnd = endHour * 60 + endMinute;

        if (quietStart < quietEnd) {
            return currentTime >= quietStart && currentTime <= quietEnd;
        } else {
            // Quiet hours span midnight
            return currentTime >= quietStart || currentTime <= quietEnd;
        }
    }

    /**
     * Get service status
     */
    static getStatus(): { running: boolean; uptime?: number } {
        return {
            running: this.isRunning
        };
    }
}
