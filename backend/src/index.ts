import express, { Request, Response } from 'express';
import http from 'http';
import dotenv from 'dotenv';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';

// Import configurations
import pool from './config/database';
import { connectRedis } from './config/redis';
import logger from './config/logger';

// Import routes
import authRoutes from './routes/authRoutes';
import routeRoutes from './routes/routeRoutes';
import checklistRoutes from './routes/checklistRoutes';

// Import services
import { TrackingService } from './services/trackingService';
import { WebSocketService } from './services/websocketService';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const API_VERSION = process.env.API_VERSION || 'v1';

// Create HTTP server
const httpServer = http.createServer(app);

// Initialize WebSocket
let wsService: WebSocketService;

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS
app.use(compression()); // Compress responses
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies
app.use(morgan('combined', {
    stream: {
        write: (message: string) => logger.info(message.trim())
    }
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'), // 15 minutes
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'), // Limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.'
});

app.use(`/api/${API_VERSION}`, limiter);

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
    res.status(200).json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        websocket: {
            connected_clients: wsService ? wsService.getConnectionCount() : 0
        },
        tracking: TrackingService.getStatus()
    });
});

// API Routes
app.use(`/api/${API_VERSION}/auth`, authRoutes);
app.use(`/api/${API_VERSION}/routes`, routeRoutes);
app.use(`/api/${API_VERSION}/checklist`, checklistRoutes);

// Root endpoint
app.get('/', (req: Request, res: Response) => {
    res.json({
        name: 'BusAlert API',
        version: API_VERSION,
        description: 'Smart Bus Arrival Notification System',
        endpoints: {
            health: '/health',
            auth: `/api/${API_VERSION}/auth`,
            routes: `/api/${API_VERSION}/routes`,
            checklist: `/api/${API_VERSION}/checklist`,
            websocket: '/ws'
        },
        documentation: 'https://github.com/Uri-cyber/BusKing'
    });
});

// 404 handler
app.use((req: Request, res: Response) => {
    res.status(404).json({
        status: 'error',
        message: 'Endpoint not found',
        path: req.path
    });
});

// Error handler
app.use((err: any, req: Request, res: Response, next: any) => {
    logger.error('Unhandled error:', err);

    res.status(err.status || 500).json({
        status: 'error',
        message: err.message || 'Internal server error',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// Initialize database and start server
async function bootstrap() {
    try {
        // Test database connection
        await pool.query('SELECT NOW()');
        logger.info('✅ Database connection established');

        // Connect to Redis
        await connectRedis();
        logger.info('✅ Redis connection established');

        // Initialize WebSocket service
        wsService = new WebSocketService(httpServer);

        // Start the HTTP server
        httpServer.listen(PORT, () => {
            logger.info(`🚀 BusAlert API server running on port ${PORT}`);
            logger.info(`📡 Environment: ${process.env.NODE_ENV || 'development'}`);
            logger.info(`🌐 API Base URL: http://localhost:${PORT}/api/${API_VERSION}`);
            logger.info(`🔌 WebSocket URL: ws://localhost:${PORT}/ws`);
        });

        // Start tracking service
        TrackingService.start();

        // Graceful shutdown
        process.on('SIGTERM', async () => {
            logger.info('SIGTERM signal received: closing HTTP server');
            TrackingService.stop();
            httpServer.close(() => {
                logger.info('HTTP server closed');
                pool.end();
                process.exit(0);
            });
        });

        process.on('SIGINT', async () => {
            logger.info('SIGINT signal received: closing HTTP server');
            TrackingService.stop();
            httpServer.close(() => {
                logger.info('HTTP server closed');
                pool.end();
                process.exit(0);
            });
        });

    } catch (error) {
        logger.error('Failed to start server:', error);
        process.exit(1);
    }
}

// Start the application
bootstrap();

export default app;
