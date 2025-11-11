import axios from 'axios';
import { BusRealtime, GTFSStop, GeoLocation } from '../types';
import { setCache, getCache } from '../config/redis';
import logger from '../config/logger';
import dotenv from 'dotenv';

dotenv.config();

const GTFS_API_URL = process.env.GTFS_API_URL || 'https://gtfs.mot.gov.il/gtfsrt/siri/vehicle_monitoring';
const CACHE_TTL = 60; // 60 seconds

export class GTFSService {
    /**
     * Get real-time bus data for a specific route and stop
     */
    static async getBusETA(route_number: string, stop_id: string): Promise<BusRealtime | null> {
        try {
            const cacheKey = `gtfs:eta:${route_number}:${stop_id}`;
            const cached = await getCache(cacheKey);

            if (cached) {
                logger.info(`GTFS cache hit for ${route_number} at stop ${stop_id}`);
                return cached;
            }

            // Fetch from GTFS-RT API
            const response = await axios.get(GTFS_API_URL, {
                params: {
                    StopMonitoringDetailLevel: 'normal',
                    LineRef: route_number,
                    MonitoringRef: stop_id
                },
                timeout: 5000
            });

            // Parse SIRI format response
            const monitoring = response.data?.Siri?.ServiceDelivery?.StopMonitoringDelivery?.[0]?.MonitoredStopVisit;

            if (!monitoring || monitoring.length === 0) {
                logger.warn(`No GTFS data found for route ${route_number} at stop ${stop_id}`);
                return null;
            }

            const visit = monitoring[0];
            const journey = visit.MonitoredVehicleJourney;

            const eta_minutes = this.calculateETA(journey.MonitoredCall?.ExpectedArrivalTime);
            const vehicle_location = journey.VehicleLocation ? {
                lat: parseFloat(journey.VehicleLocation.Latitude),
                lon: parseFloat(journey.VehicleLocation.Longitude)
            } : null;

            const busData: BusRealtime = {
                route_number,
                stop_id,
                eta_minutes,
                vehicle_location: vehicle_location!,
                trip_id: journey.FramedVehicleJourneyRef?.DatedVehicleJourneyRef,
                vehicle_id: journey.VehicleRef,
                timestamp: new Date()
            };

            // Cache the result
            await setCache(cacheKey, busData, CACHE_TTL);

            logger.info(`GTFS fetched for route ${route_number}, ETA: ${eta_minutes} min`);
            return busData;
        } catch (error) {
            logger.error('GTFS API error:', error);
            return null;
        }
    }

    /**
     * Calculate ETA in minutes from ISO timestamp
     */
    private static calculateETA(expectedArrival: string): number {
        if (!expectedArrival) return 0;

        const arrivalTime = new Date(expectedArrival);
        const now = new Date();
        const diffMs = arrivalTime.getTime() - now.getTime();
        const diffMinutes = Math.round(diffMs / 60000);

        return Math.max(0, diffMinutes);
    }

    /**
     * Get all buses for a specific route (useful for showing alternatives)
     */
    static async getAllBusesForRoute(route_number: string): Promise<BusRealtime[]> {
        try {
            const response = await axios.get(GTFS_API_URL, {
                params: {
                    LineRef: route_number
                },
                timeout: 5000
            });

            const monitoring = response.data?.Siri?.ServiceDelivery?.StopMonitoringDelivery?.[0]?.MonitoredStopVisit || [];

            return monitoring.map((visit: any) => {
                const journey = visit.MonitoredVehicleJourney;
                return {
                    route_number,
                    stop_id: visit.MonitoringRef,
                    eta_minutes: this.calculateETA(journey.MonitoredCall?.ExpectedArrivalTime),
                    vehicle_location: journey.VehicleLocation ? {
                        lat: parseFloat(journey.VehicleLocation.Latitude),
                        lon: parseFloat(journey.VehicleLocation.Longitude)
                    } : null,
                    trip_id: journey.FramedVehicleJourneyRef?.DatedVehicleJourneyRef,
                    vehicle_id: journey.VehicleRef,
                    timestamp: new Date()
                };
            });
        } catch (error) {
            logger.error('GTFS getAllBusesForRoute error:', error);
            return [];
        }
    }

    /**
     * Find nearby stops based on GPS coordinates
     */
    static async findNearbyStops(location: GeoLocation, radius: number = 500): Promise<GTFSStop[]> {
        try {
            const cacheKey = `gtfs:stops:${location.lat}:${location.lon}:${radius}`;
            const cached = await getCache(cacheKey);

            if (cached) {
                return cached;
            }

            // In production, this would query the GTFS stops database
            // For now, return empty array
            // TODO: Implement GTFS stops import and spatial query

            logger.warn('findNearbyStops not yet implemented');
            return [];
        } catch (error) {
            logger.error('findNearbyStops error:', error);
            return [];
        }
    }

    /**
     * Check if a bus is delayed
     */
    static isDelayed(eta_minutes: number, expected_eta: number): boolean {
        return eta_minutes > expected_eta + 5;
    }

    /**
     * Check if a bus is early
     */
    static isEarly(eta_minutes: number, expected_eta: number): boolean {
        return eta_minutes < expected_eta - 3;
    }
}
