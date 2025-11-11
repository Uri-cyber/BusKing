-- BusAlert Database Schema
-- PostgreSQL 14+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    whatsapp_number VARCHAR(20),
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    settings JSONB DEFAULT '{
        "preferred_channel": "whatsapp",
        "quiet_mode": true,
        "quiet_hours": ["22:00", "06:00"],
        "language": "he",
        "alert_minutes_before": 5
    }'::jsonb,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP
);

CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_active ON users(is_active);

-- User routes (scheduled tracking)
CREATE TABLE user_routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    stop_id VARCHAR(10) NOT NULL,
    stop_name VARCHAR(200),
    stop_location JSONB, -- {"lat": 32.0853, "lon": 34.7818}
    route_number VARCHAR(10) NOT NULL,
    route_name VARCHAR(200),
    days_of_week INTEGER[] NOT NULL, -- [1,2,3,4,5] = Mon-Fri, 0 = Sun, 6 = Sat
    time_window_start TIME NOT NULL,
    time_window_end TIME NOT NULL,
    alert_minutes_before INTEGER DEFAULT 5,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_user_routes_user ON user_routes(user_id);
CREATE INDEX idx_user_routes_active ON user_routes(is_active);
CREATE INDEX idx_user_routes_schedule ON user_routes(days_of_week, time_window_start);

-- Checklist items
CREATE TABLE checklist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    item_name VARCHAR(100) NOT NULL,
    emoji VARCHAR(10),
    is_default BOOLEAN DEFAULT true,
    context VARCHAR(50), -- 'always', 'morning', 'evening', 'rainy', 'hot'
    condition_value VARCHAR(50), -- for contextual items (e.g., 'temp > 30' for hot)
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_checklist_user ON checklist_items(user_id);
CREATE INDEX idx_checklist_context ON checklist_items(context);

-- Alert history
CREATE TABLE alert_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    route_id UUID REFERENCES user_routes(id) ON DELETE SET NULL,
    alert_type VARCHAR(20) NOT NULL, -- 'initial', 'checklist', 'urgent', 'delayed', 'cancelled'
    eta_minutes INTEGER,
    bus_location JSONB, -- {"lat": 32.0853, "lon": 34.7818}
    message TEXT,
    channel VARCHAR(20), -- 'whatsapp', 'push', 'sms'
    sent_at TIMESTAMP DEFAULT NOW(),
    was_accurate BOOLEAN, -- user feedback
    user_feedback TEXT
);

CREATE INDEX idx_alert_history_user ON alert_history(user_id);
CREATE INDEX idx_alert_history_sent_at ON alert_history(sent_at);
CREATE INDEX idx_alert_history_route ON alert_history(route_id);

-- Bus tracking sessions (active tracking)
CREATE TABLE tracking_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    route_id UUID REFERENCES user_routes(id) ON DELETE SET NULL,
    stop_id VARCHAR(10) NOT NULL,
    route_number VARCHAR(10) NOT NULL,
    started_at TIMESTAMP DEFAULT NOW(),
    ended_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'cancelled'
    actual_arrival_time TIMESTAMP,
    initial_eta INTEGER, -- in minutes
    final_eta INTEGER
);

CREATE INDEX idx_tracking_sessions_user ON tracking_sessions(user_id);
CREATE INDEX idx_tracking_sessions_status ON tracking_sessions(status);

-- GTFS cache (for faster lookups)
CREATE TABLE gtfs_stops (
    stop_id VARCHAR(10) PRIMARY KEY,
    stop_name VARCHAR(200) NOT NULL,
    stop_lat DECIMAL(10, 7) NOT NULL,
    stop_lon DECIMAL(10, 7) NOT NULL,
    location_type INTEGER DEFAULT 0,
    parent_station VARCHAR(10),
    stop_code VARCHAR(20),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_gtfs_stops_location ON gtfs_stops(stop_lat, stop_lon);
CREATE INDEX idx_gtfs_stops_name ON gtfs_stops(stop_name);

CREATE TABLE gtfs_routes (
    route_id VARCHAR(20) PRIMARY KEY,
    route_short_name VARCHAR(10) NOT NULL,
    route_long_name VARCHAR(200),
    route_type INTEGER,
    agency_id VARCHAR(20),
    route_color VARCHAR(6),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_gtfs_routes_short_name ON gtfs_routes(route_short_name);

-- User statistics
CREATE TABLE user_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    stat_date DATE NOT NULL,
    buses_tracked INTEGER DEFAULT 0,
    buses_caught INTEGER DEFAULT 0,
    time_saved_minutes INTEGER DEFAULT 0, -- estimated time saved waiting
    most_used_route VARCHAR(10),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, stat_date)
);

CREATE INDEX idx_user_statistics_user_date ON user_statistics(user_id, stat_date);

-- Shared location sessions (for real-time sharing)
CREATE TABLE shared_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tracking_session_id UUID REFERENCES tracking_sessions(id) ON DELETE CASCADE,
    share_token VARCHAR(100) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_shared_locations_token ON shared_locations(share_token);
CREATE INDEX idx_shared_locations_expires ON shared_locations(expires_at);

-- SMS/WhatsApp verification codes
CREATE TABLE verification_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT false,
    attempts INTEGER DEFAULT 0
);

CREATE INDEX idx_verification_codes_phone ON verification_codes(phone_number);
CREATE INDEX idx_verification_codes_expires ON verification_codes(expires_at);

-- Functions and triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_routes_updated_at BEFORE UPDATE ON user_routes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Default checklist items
INSERT INTO checklist_items (id, user_id, item_name, emoji, context, is_default, display_order)
VALUES
    (uuid_generate_v4(), NULL, 'טלפון', '📱', 'always', true, 1),
    (uuid_generate_v4(), NULL, 'מפתחות', '🔑', 'always', true, 2),
    (uuid_generate_v4(), NULL, 'ארנק', '💳', 'always', true, 3),
    (uuid_generate_v4(), NULL, 'אוזניות', '🎧', 'always', true, 4),
    (uuid_generate_v4(), NULL, 'מטריה', '☂️', 'rainy', true, 5),
    (uuid_generate_v4(), NULL, 'בקבוק מים', '💧', 'hot', true, 6),
    (uuid_generate_v4(), NULL, 'ארוחת בוקר', '🥐', 'morning', true, 7),
    (uuid_generate_v4(), NULL, 'מעיל', '🧥', 'cold', true, 8);
