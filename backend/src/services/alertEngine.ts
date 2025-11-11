import { GTFSService } from './gtfsService';
import { WhatsAppService } from './whatsappService';
import { WeatherService } from './weatherService';
import { ChecklistModel } from '../models/Checklist';
import { query } from '../config/database';
import { setCache, getCache } from '../config/redis';
import logger from '../config/logger';
import { UserRoute, ChecklistItem } from '../types';

export type AlertType = 'initial' | 'checklist' | 'urgent' | 'delayed' | 'cancelled';

interface AlertState {
    route_id: string;
    last_alert: AlertType | null;
    initial_eta: number;
    last_eta: number;
    alerts_sent: AlertType[];
}

export class AlertEngine {
    private static alertStates: Map<string, AlertState> = new Map();

    /**
     * Main method to check and send alerts for a route
     */
    static async checkAndSendAlerts(route: UserRoute, user_phone: string): Promise<void> {
        try {
            const { stop_id, route_number, alert_minutes_before, user_id } = route;

            // Get real-time bus data
            const busData = await GTFSService.getBusETA(route_number, stop_id);

            if (!busData) {
                logger.warn(`No bus data for route ${route_number} at stop ${stop_id}`);
                return;
            }

            const { eta_minutes } = busData;
            const stateKey = `alert:${route.id}`;
            let state = this.alertStates.get(stateKey);

            if (!state) {
                state = {
                    route_id: route.id,
                    last_alert: null,
                    initial_eta: eta_minutes,
                    last_eta: eta_minutes,
                    alerts_sent: []
                };
                this.alertStates.set(stateKey, state);
            }

            // Determine which alert to send
            await this.processAlerts(route, user_phone, user_id, eta_minutes, state);

            // Update state
            state.last_eta = eta_minutes;
        } catch (error) {
            logger.error('Alert engine error:', error);
        }
    }

    /**
     * Process and send appropriate alerts based on ETA
     */
    private static async processAlerts(
        route: UserRoute,
        phone: string,
        user_id: string,
        eta_minutes: number,
        state: AlertState
    ): Promise<void> {
        const { route_number, stop_name } = route;

        // Stage 1: Initial alert (10 minutes before)
        if (eta_minutes <= 10 && !state.alerts_sent.includes('initial')) {
            await WhatsAppService.sendInitialAlert(phone, route_number, eta_minutes, stop_name);
            await this.logAlert(user_id, route.id, 'initial', eta_minutes, 'whatsapp');
            state.alerts_sent.push('initial');
            state.last_alert = 'initial';
            logger.info(`Initial alert sent for route ${route_number}`);
        }

        // Stage 2: Checklist alert (5 minutes before)
        if (eta_minutes <= 5 && !state.alerts_sent.includes('checklist')) {
            await this.sendChecklistAlert(user_id, phone, route_number, eta_minutes);
            await this.logAlert(user_id, route.id, 'checklist', eta_minutes, 'whatsapp');
            state.alerts_sent.push('checklist');
            state.last_alert = 'checklist';
            logger.info(`Checklist alert sent for route ${route_number}`);
        }

        // Stage 3: Urgent alert (2 minutes before)
        if (eta_minutes <= 2 && !state.alerts_sent.includes('urgent')) {
            await WhatsAppService.sendUrgentAlert(phone, route_number, eta_minutes);
            await this.logAlert(user_id, route.id, 'urgent', eta_minutes, 'whatsapp');
            state.alerts_sent.push('urgent');
            state.last_alert = 'urgent';
            logger.info(`Urgent alert sent for route ${route_number}`);
        }

        // Check for delays (ETA increased by 5+ minutes)
        if (state.last_eta > 0 && eta_minutes > state.last_eta + 5 && !state.alerts_sent.includes('delayed')) {
            const delay = eta_minutes - state.last_eta;
            await WhatsAppService.sendDelayedAlert(phone, route_number, delay, eta_minutes);
            await this.logAlert(user_id, route.id, 'delayed', eta_minutes, 'whatsapp');
            state.alerts_sent.push('delayed');
            logger.info(`Delayed alert sent for route ${route_number}, delay: ${delay} min`);
        }
    }

    /**
     * Send checklist alert with contextual items
     */
    private static async sendChecklistAlert(
        user_id: string,
        phone: string,
        route_number: string,
        eta_minutes: number
    ): Promise<void> {
        try {
            // Get weather and time context
            const context = await WeatherService.getFullContext();

            // Get contextual checklist
            const items = await ChecklistModel.getContextualChecklist(user_id, context);

            const checklistText = items.map((item: ChecklistItem) =>
                `${item.emoji || '•'} ${item.item_name}`
            );

            await WhatsAppService.sendChecklistAlert(phone, eta_minutes, route_number, checklistText);
        } catch (error) {
            logger.error('Send checklist alert error:', error);
        }
    }

    /**
     * Log alert to database
     */
    private static async logAlert(
        user_id: string,
        route_id: string,
        alert_type: AlertType,
        eta_minutes: number,
        channel: string
    ): Promise<void> {
        try {
            await query(
                `INSERT INTO alert_history (user_id, route_id, alert_type, eta_minutes, channel)
                 VALUES ($1, $2, $3, $4, $5)`,
                [user_id, route_id, alert_type, eta_minutes, channel]
            );
        } catch (error) {
            logger.error('Log alert error:', error);
        }
    }

    /**
     * Clear alert state for a route (when tracking ends)
     */
    static clearAlertState(route_id: string): void {
        const stateKey = `alert:${route_id}`;
        this.alertStates.delete(stateKey);
    }

    /**
     * Get alert state for debugging
     */
    static getAlertState(route_id: string): AlertState | undefined {
        const stateKey = `alert:${route_id}`;
        return this.alertStates.get(stateKey);
    }
}
