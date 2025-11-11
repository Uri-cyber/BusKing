const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'busalert',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
});

async function seed() {
    try {
        console.log('🌱 Starting database seeding...');

        // Insert sample GTFS stops (Tel Aviv area)
        await pool.query(`
            INSERT INTO gtfs_stops (stop_id, stop_name, stop_lat, stop_lon, stop_code)
            VALUES
                ('3045', 'רחוב הרצל 45 / וייצמן', 32.0853, 34.7818, '3045'),
                ('4567', 'דיזנגוף / פרישמן', 32.0781, 34.7731, '4567'),
                ('7890', 'אלנבי / שנקין', 32.0656, 34.7706, '7890'),
                ('1234', 'רוטשילד / אחד העם', 32.0642, 34.7722, '1234'),
                ('5678', 'יפו / ברקוביץ', 32.0511, 34.7562, '5678')
            ON CONFLICT (stop_id) DO NOTHING;
        `);

        console.log('✅ Inserted sample bus stops');

        // Insert sample routes
        await pool.query(`
            INSERT INTO gtfs_routes (route_id, route_short_name, route_long_name, route_type)
            VALUES
                ('18', '18', 'תל אביב תחנה מרכזית - בת ים', 3),
                ('5', '5', 'תל אביב תחנה מרכזית - חולון', 3),
                ('61', '61', 'תל אביב רמת אביב - יפו', 3),
                ('125', '125', 'תל אביב - רמת גן', 3)
            ON CONFLICT (route_id) DO NOTHING;
        `);

        console.log('✅ Inserted sample bus routes');

        console.log('✅ Database seeding completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Seeding failed:', error);
        process.exit(1);
    }
}

seed();
