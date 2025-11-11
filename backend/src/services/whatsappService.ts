import axios from 'axios';
import logger from '../config/logger';
import dotenv from 'dotenv';

dotenv.config();

const WHATSAPP_API_URL = process.env.WHATSAPP_API_URL || 'https://graph.facebook.com/v18.0';
const PHONE_NUMBER_ID = process.env.WHATSAPP_PHONE_NUMBER_ID;
const ACCESS_TOKEN = process.env.WHATSAPP_ACCESS_TOKEN;

export interface WhatsAppMessage {
    to: string;
    type: 'text' | 'template' | 'interactive';
    text?: {
        body: string;
    };
    template?: any;
    interactive?: any;
}

export class WhatsAppService {
    /**
     * Send a text message via WhatsApp
     */
    static async sendTextMessage(phone_number: string, message: string): Promise<boolean> {
        try {
            if (process.env.NODE_ENV === 'development') {
                logger.info(`📱 WhatsApp message to ${phone_number}: ${message}`);
                return true;
            }

            const payload = {
                messaging_product: 'whatsapp',
                to: phone_number,
                type: 'text',
                text: {
                    body: message
                }
            };

            const response = await axios.post(
                `${WHATSAPP_API_URL}/${PHONE_NUMBER_ID}/messages`,
                payload,
                {
                    headers: {
                        'Authorization': `Bearer ${ACCESS_TOKEN}`,
                        'Content-Type': 'application/json'
                    }
                }
            );

            logger.info(`✅ WhatsApp message sent to ${phone_number}`);
            return true;
        } catch (error) {
            logger.error('WhatsApp send error:', error);
            return false;
        }
    }

    /**
     * Send alert with quick reply buttons
     */
    static async sendAlertWithButtons(
        phone_number: string,
        message: string,
        buttons: { id: string; title: string }[]
    ): Promise<boolean> {
        try {
            if (process.env.NODE_ENV === 'development') {
                logger.info(`📱 WhatsApp alert to ${phone_number}: ${message}`);
                logger.info(`Buttons: ${buttons.map(b => b.title).join(', ')}`);
                return true;
            }

            const payload = {
                messaging_product: 'whatsapp',
                to: phone_number,
                type: 'interactive',
                interactive: {
                    type: 'button',
                    body: {
                        text: message
                    },
                    action: {
                        buttons: buttons.slice(0, 3).map(btn => ({
                            type: 'reply',
                            reply: {
                                id: btn.id,
                                title: btn.title
                            }
                        }))
                    }
                }
            };

            await axios.post(
                `${WHATSAPP_API_URL}/${PHONE_NUMBER_ID}/messages`,
                payload,
                {
                    headers: {
                        'Authorization': `Bearer ${ACCESS_TOKEN}`,
                        'Content-Type': 'application/json'
                    }
                }
            );

            logger.info(`✅ WhatsApp interactive message sent to ${phone_number}`);
            return true;
        } catch (error) {
            logger.error('WhatsApp send interactive error:', error);
            return false;
        }
    }

    /**
     * Send alert with checklist
     */
    static async sendChecklistAlert(
        phone_number: string,
        eta_minutes: number,
        route_number: string,
        checklist: string[]
    ): Promise<boolean> {
        const checklistText = checklist.map((item, idx) => `${idx + 1}. ${item}`).join('\n');

        const message = `🚌 *קו ${route_number} מגיע בעוד ${eta_minutes} דקות!*\n\n✅ *תזכורת - אל תשכח:*\n${checklistText}\n\n🏃‍♂️ זמן לצאת!`;

        return this.sendTextMessage(phone_number, message);
    }

    /**
     * Send initial alert (10 minutes before)
     */
    static async sendInitialAlert(
        phone_number: string,
        route_number: string,
        eta_minutes: number,
        stop_name?: string
    ): Promise<boolean> {
        const locationText = stop_name ? ` לתחנה ${stop_name}` : '';
        const message = `🚌 *קו ${route_number}*\n\nמגיע${locationText} בעוד *${eta_minutes} דקות*\n\n⏰ התרעה נוספת תגיע בעוד 5 דקות`;

        return this.sendTextMessage(phone_number, message);
    }

    /**
     * Send urgent alert (2 minutes before)
     */
    static async sendUrgentAlert(
        phone_number: string,
        route_number: string,
        eta_minutes: number
    ): Promise<boolean> {
        const message = `🚨 *דחוף!*\n\nקו ${route_number} מגיע בעוד *${eta_minutes} דקות*!\n\n🏃‍♂️ צא עכשיו!`;

        return this.sendAlertWithButtons(phone_number, message, [
            { id: 'on_my_way', title: '👍 יצאתי' },
            { id: 'skip', title: '⏭ דלג' }
        ]);
    }

    /**
     * Send delayed bus alert
     */
    static async sendDelayedAlert(
        phone_number: string,
        route_number: string,
        delay_minutes: number,
        new_eta: number
    ): Promise<boolean> {
        const message = `⏱ *עדכון - קו ${route_number}*\n\nהאוטובוס מאחר ב-${delay_minutes} דקות\nהגעה צפויה בעוד *${new_eta} דקות*`;

        return this.sendTextMessage(phone_number, message);
    }

    /**
     * Send cancelled bus alert with alternatives
     */
    static async sendCancelledAlert(
        phone_number: string,
        route_number: string,
        alternatives?: string[]
    ): Promise<boolean> {
        let message = `❌ *קו ${route_number} בוטל*\n\n`;

        if (alternatives && alternatives.length > 0) {
            message += `🚌 *אלטרנטיבות:*\n${alternatives.join('\n')}`;
        } else {
            message += 'לא נמצאו אוטובוסים חלופיים בזמן הקרוב.';
        }

        return this.sendTextMessage(phone_number, message);
    }

    /**
     * Format phone number to WhatsApp format (remove + and spaces)
     */
    static formatPhoneNumber(phone: string): string {
        return phone.replace(/[+\s-]/g, '');
    }
}
