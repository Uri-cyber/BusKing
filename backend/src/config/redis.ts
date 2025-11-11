import { createClient } from 'redis';
import dotenv from 'dotenv';

dotenv.config();

const redisClient = createClient({
    socket: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
    },
    password: process.env.REDIS_PASSWORD || undefined,
});

redisClient.on('connect', () => {
    console.log('✅ Redis connected successfully');
});

redisClient.on('error', (err) => {
    console.error('❌ Redis error:', err);
});

export const connectRedis = async () => {
    try {
        await redisClient.connect();
    } catch (error) {
        console.error('Failed to connect to Redis:', error);
        throw error;
    }
};

// Helper functions
export const setCache = async (key: string, value: any, expireInSeconds: number = 3600) => {
    try {
        await redisClient.setEx(key, expireInSeconds, JSON.stringify(value));
    } catch (error) {
        console.error('Redis setCache error:', error);
    }
};

export const getCache = async (key: string): Promise<any | null> => {
    try {
        const data = await redisClient.get(key);
        return data ? JSON.parse(data) : null;
    } catch (error) {
        console.error('Redis getCache error:', error);
        return null;
    }
};

export const deleteCache = async (key: string) => {
    try {
        await redisClient.del(key);
    } catch (error) {
        console.error('Redis deleteCache error:', error);
    }
};

export const clearCachePattern = async (pattern: string) => {
    try {
        const keys = await redisClient.keys(pattern);
        if (keys.length > 0) {
            await redisClient.del(keys);
        }
    } catch (error) {
        console.error('Redis clearCachePattern error:', error);
    }
};

export default redisClient;
