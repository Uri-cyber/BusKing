// User types
export interface User {
    id: string;
    phone_number: string;
    whatsapp_number?: string;
    name?: string;
    created_at: Date;
    updated_at: Date;
    settings: UserSettings;
    is_active: boolean;
    last_login?: Date;
}

export interface UserSettings {
    preferred_channel: 'whatsapp' | 'push' | 'sms';
    quiet_mode: boolean;
    quiet_hours: [string, string]; // ["22:00", "06:00"]
    language: 'he' | 'en' | 'ar';
    alert_minutes_before: number;
}

// Route types
export interface UserRoute {
    id: string;
    user_id: string;
    stop_id: string;
    stop_name?: string;
    stop_location?: GeoLocation;
    route_number: string;
    route_name?: string;
    days_of_week: number[]; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    time_window_start: string; // "07:30"
    time_window_end: string; // "08:00"
    alert_minutes_before: number;
    is_active: boolean;
    created_at: Date;
    updated_at: Date;
}

// Checklist types
export interface ChecklistItem {
    id: string;
    user_id?: string;
    item_name: string;
    emoji?: string;
    is_default: boolean;
    context?: 'always' | 'morning' | 'evening' | 'rainy' | 'hot' | 'cold';
    condition_value?: string;
    display_order: number;
    is_active: boolean;
    created_at: Date;
}

// Alert types
export interface AlertHistory {
    id: string;
    user_id: string;
    route_id?: string;
    alert_type: 'initial' | 'checklist' | 'urgent' | 'delayed' | 'cancelled';
    eta_minutes?: number;
    bus_location?: GeoLocation;
    message?: string;
    channel: 'whatsapp' | 'push' | 'sms';
    sent_at: Date;
    was_accurate?: boolean;
    user_feedback?: string;
}

// Tracking types
export interface TrackingSession {
    id: string;
    user_id: string;
    route_id?: string;
    stop_id: string;
    route_number: string;
    started_at: Date;
    ended_at?: Date;
    status: 'active' | 'completed' | 'cancelled';
    actual_arrival_time?: Date;
    initial_eta?: number;
    final_eta?: number;
}

// GTFS types
export interface GTFSStop {
    stop_id: string;
    stop_name: string;
    stop_lat: number;
    stop_lon: number;
    location_type?: number;
    parent_station?: string;
    stop_code?: string;
}

export interface GTFSRoute {
    route_id: string;
    route_short_name: string;
    route_long_name?: string;
    route_type?: number;
    agency_id?: string;
    route_color?: string;
}

export interface BusRealtime {
    route_number: string;
    stop_id: string;
    eta_minutes: number;
    vehicle_location: GeoLocation;
    trip_id?: string;
    vehicle_id?: string;
    timestamp: Date;
}

// Common types
export interface GeoLocation {
    lat: number;
    lon: number;
}

export interface ApiResponse<T = any> {
    status: 'success' | 'error';
    message?: string;
    data?: T;
    error?: string;
}

// Request/Response types
export interface RegisterRequest {
    phone_number: string;
    name?: string;
}

export interface VerifyRequest {
    phone_number: string;
    code: string;
}

export interface AuthResponse {
    token: string;
    user: Partial<User>;
}

export interface CreateRouteRequest {
    stop_id: string;
    stop_name?: string;
    route_number: string;
    route_name?: string;
    days_of_week: number[];
    time_window_start: string;
    time_window_end: string;
    alert_minutes_before?: number;
}

export interface StartTrackingRequest {
    stop_id: string;
    route_number: string;
}

export interface CreateChecklistItemRequest {
    item_name: string;
    emoji?: string;
    context?: string;
}

// Weather types
export interface WeatherData {
    temp: number;
    feels_like: number;
    humidity: number;
    description: string;
    rain: boolean;
    timestamp: Date;
}
