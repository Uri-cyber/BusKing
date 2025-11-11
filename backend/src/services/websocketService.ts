import { Server as SocketServer, Socket } from 'socket.io';
import { Server as HTTPServer } from 'http';
import { verifyToken } from '../utils/jwt';
import logger from '../config/logger';

interface AuthenticatedSocket extends Socket {
    userId?: string;
}

export class WebSocketService {
    private io: SocketServer;
    private userSockets: Map<string, string> = new Map(); // userId -> socketId

    constructor(httpServer: HTTPServer) {
        this.io = new SocketServer(httpServer, {
            cors: {
                origin: process.env.CORS_ORIGIN || '*',
                methods: ['GET', 'POST']
            },
            path: '/ws'
        });

        this.setupMiddleware();
        this.setupEventHandlers();

        logger.info('✅ WebSocket server initialized');
    }

    /**
     * Setup authentication middleware
     */
    private setupMiddleware(): void {
        this.io.use((socket: AuthenticatedSocket, next) => {
            try {
                const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.substring(7);

                if (!token) {
                    return next(new Error('Authentication error: No token provided'));
                }

                const decoded = verifyToken(token);

                if (!decoded) {
                    return next(new Error('Authentication error: Invalid token'));
                }

                socket.userId = decoded.user_id;
                next();
            } catch (error) {
                next(new Error('Authentication error'));
            }
        });
    }

    /**
     * Setup event handlers
     */
    private setupEventHandlers(): void {
        this.io.on('connection', (socket: AuthenticatedSocket) => {
            const userId = socket.userId!;

            logger.info(`WebSocket client connected: ${socket.id} (User: ${userId})`);

            // Store socket for user
            this.userSockets.set(userId, socket.id);

            // Join user to their own room
            socket.join(`user:${userId}`);

            // Handle disconnection
            socket.on('disconnect', () => {
                logger.info(`WebSocket client disconnected: ${socket.id}`);
                this.userSockets.delete(userId);
            });

            // Handle ping
            socket.on('ping', () => {
                socket.emit('pong', { timestamp: Date.now() });
            });

            // Handle tracking status request
            socket.on('get_tracking_status', () => {
                // TODO: Implement get tracking status
                socket.emit('tracking_status', {
                    active: false
                });
            });
        });
    }

    /**
     * Send bus update to a specific user
     */
    sendBusUpdate(userId: string, data: {
        route_number: string;
        stop_id: string;
        eta_minutes: number;
        vehicle_location?: { lat: number; lon: number };
    }): void {
        this.io.to(`user:${userId}`).emit('bus_update', data);
        logger.info(`Bus update sent to user ${userId}`);
    }

    /**
     * Send alert triggered notification
     */
    sendAlertTriggered(userId: string, data: {
        alert_type: string;
        route_number: string;
        eta_minutes: number;
        message: string;
    }): void {
        this.io.to(`user:${userId}`).emit('alert_triggered', data);
        logger.info(`Alert triggered notification sent to user ${userId}`);
    }

    /**
     * Send tracking status change
     */
    sendTrackingStatus(userId: string, data: {
        status: 'started' | 'stopped';
        route_number?: string;
        stop_id?: string;
    }): void {
        this.io.to(`user:${userId}`).emit('tracking_status', data);
        logger.info(`Tracking status sent to user ${userId}`);
    }

    /**
     * Broadcast message to all connected clients
     */
    broadcast(event: string, data: any): void {
        this.io.emit(event, data);
        logger.info(`Broadcast: ${event}`);
    }

    /**
     * Get number of connected clients
     */
    getConnectionCount(): number {
        return this.io.sockets.sockets.size;
    }

    /**
     * Get connected users
     */
    getConnectedUsers(): string[] {
        return Array.from(this.userSockets.keys());
    }
}
