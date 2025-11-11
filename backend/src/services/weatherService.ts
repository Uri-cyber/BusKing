import axios from 'axios';
import { WeatherData } from '../types';
import { setCache, getCache } from '../config/redis';
import logger from '../config/logger';
import dotenv from 'dotenv';

dotenv.config();

const WEATHER_API_KEY = process.env.WEATHER_API_KEY;
const WEATHER_API_URL = process.env.WEATHER_API_URL || 'https://api.openweathermap.org/data/2.5/weather';
const CACHE_TTL = 3600; // 1 hour

export class WeatherService {
    /**
     * Get current weather for a location
     */
    static async getWeather(lat: number, lon: number): Promise<WeatherData | null> {
        try {
            const cacheKey = `weather:${lat}:${lon}`;
            const cached = await getCache(cacheKey);

            if (cached) {
                logger.info('Weather cache hit');
                return cached;
            }

            const response = await axios.get(WEATHER_API_URL, {
                params: {
                    lat,
                    lon,
                    appid: WEATHER_API_KEY,
                    units: 'metric',
                    lang: 'he'
                },
                timeout: 5000
            });

            const data = response.data;

            const weatherData: WeatherData = {
                temp: Math.round(data.main.temp),
                feels_like: Math.round(data.main.feels_like),
                humidity: data.main.humidity,
                description: data.weather[0].description,
                rain: data.weather[0].main === 'Rain' || data.weather[0].main === 'Drizzle',
                timestamp: new Date()
            };

            await setCache(cacheKey, weatherData, CACHE_TTL);

            logger.info(`Weather fetched: ${weatherData.temp}°C, ${weatherData.description}`);
            return weatherData;
        } catch (error) {
            logger.error('Weather API error:', error);
            return null;
        }
    }

    /**
     * Get weather for Tel Aviv (default location for Israel)
     */
    static async getDefaultWeather(): Promise<WeatherData | null> {
        // Tel Aviv coordinates
        return this.getWeather(32.0853, 34.7818);
    }

    /**
     * Determine checklist context based on weather
     */
    static getChecklistContext(weather: WeatherData): {
        isRainy: boolean;
        isHot: boolean;
        isCold: boolean;
    } {
        return {
            isRainy: weather.rain,
            isHot: weather.temp >= 30,
            isCold: weather.temp <= 15
        };
    }

    /**
     * Get time-based checklist context
     */
    static getTimeContext(): {
        isMorning: boolean;
        isEvening: boolean;
    } {
        const hour = new Date().getHours();
        return {
            isMorning: hour >= 5 && hour < 12,
            isEvening: hour >= 18 && hour < 23
        };
    }

    /**
     * Get full contextual data for checklist
     */
    static async getFullContext(lat?: number, lon?: number): Promise<{
        isRainy: boolean;
        isHot: boolean;
        isCold: boolean;
        isMorning: boolean;
        isEvening: boolean;
    }> {
        const weather = lat && lon
            ? await this.getWeather(lat, lon)
            : await this.getDefaultWeather();

        const weatherContext = weather
            ? this.getChecklistContext(weather)
            : { isRainy: false, isHot: false, isCold: false };

        const timeContext = this.getTimeContext();

        return {
            ...weatherContext,
            ...timeContext
        };
    }
}
