import { Pool } from 'pg';
import { RedisClient } from './redisClient';

interface TrainingData {
  route_number: string;
  stop_id: string;
  day_of_week: number;
  hour: number;
  minute: number;
  actual_eta_minutes: number;
  weather_condition?: string;
  traffic_level?: number;
}

interface PredictionInput {
  route_number: string;
  stop_id: string;
  day_of_week: number;
  hour: number;
  minute: number;
  weather_condition?: string;
  traffic_level?: number;
}

interface UserPattern {
  user_id: string;
  route_number: string;
  stop_id: string;
  preferred_times: { day: number; hour: number; minute: number }[];
  frequency_score: number;
}

export class MLService {
  private db: Pool;
  private redis: RedisClient;
  private models: Map<string, any> = new Map();

  constructor(db: Pool, redis: RedisClient) {
    this.db = db;
    this.redis = redis;
  }

  /**
   * Collect training data from historical alerts
   */
  async collectTrainingData(
    route_number: string,
    stop_id: string,
    days_back: number = 30
  ): Promise<TrainingData[]> {
    const query = `
      SELECT
        ah.route_number,
        ah.stop_id,
        EXTRACT(DOW FROM ah.created_at) as day_of_week,
        EXTRACT(HOUR FROM ah.created_at) as hour,
        EXTRACT(MINUTE FROM ah.created_at) as minute,
        ah.eta_minutes as actual_eta_minutes,
        ah.metadata->>'weather' as weather_condition,
        (ah.metadata->>'traffic_level')::int as traffic_level
      FROM alert_history ah
      WHERE ah.route_number = $1
        AND ah.stop_id = $2
        AND ah.created_at >= NOW() - INTERVAL '${days_back} days'
        AND ah.alert_type = 'initial'
        AND ah.eta_minutes IS NOT NULL
      ORDER BY ah.created_at DESC
    `;

    const result = await this.db.query(query, [route_number, stop_id]);
    return result.rows;
  }

  /**
   * Train simple linear regression model for ETA prediction
   * In production, use TensorFlow.js or Python ML service
   */
  async trainETAModel(route_number: string, stop_id: string): Promise<void> {
    console.log(`🤖 Training ETA model for route ${route_number} stop ${stop_id}`);

    const trainingData = await this.collectTrainingData(route_number, stop_id);

    if (trainingData.length < 10) {
      console.log(`⚠️  Not enough data to train model (${trainingData.length} samples)`);
      return;
    }

    // Simple statistical model: calculate average ETA by time slot
    const timeSlotAverages: Map<string, { sum: number; count: number }> = new Map();

    trainingData.forEach(data => {
      // Group by day_of_week and hour
      const key = `${data.day_of_week}_${data.hour}`;

      if (!timeSlotAverages.has(key)) {
        timeSlotAverages.set(key, { sum: 0, count: 0 });
      }

      const slot = timeSlotAverages.get(key)!;
      slot.sum += data.actual_eta_minutes;
      slot.count += 1;
    });

    // Calculate averages
    const model: any = {};
    timeSlotAverages.forEach((value, key) => {
      model[key] = value.sum / value.count;
    });

    // Store model in memory and cache
    const modelKey = `ml:eta:${route_number}:${stop_id}`;
    this.models.set(modelKey, model);
    await this.redis.set(modelKey, JSON.stringify(model), 86400); // 24 hours

    console.log(`✅ Model trained with ${trainingData.length} samples`);
  }

  /**
   * Predict ETA using ML model
   */
  async predictETA(input: PredictionInput): Promise<number | null> {
    const modelKey = `ml:eta:${input.route_number}:${input.stop_id}`;

    // Try to get model from memory
    let model = this.models.get(modelKey);

    // If not in memory, try Redis
    if (!model) {
      const cached = await this.redis.get(modelKey);
      if (cached) {
        model = JSON.parse(cached);
        this.models.set(modelKey, model);
      }
    }

    // If still no model, train it
    if (!model) {
      await this.trainETAModel(input.route_number, input.stop_id);
      model = this.models.get(modelKey);
    }

    if (!model) {
      return null; // Not enough data
    }

    // Make prediction
    const key = `${input.day_of_week}_${input.hour}`;
    const prediction = model[key];

    if (prediction) {
      // Apply weather and traffic adjustments
      let adjusted = prediction;

      if (input.weather_condition === 'rain') {
        adjusted *= 1.15; // 15% increase for rain
      }

      if (input.traffic_level && input.traffic_level > 7) {
        adjusted *= 1.2; // 20% increase for heavy traffic
      }

      return Math.round(adjusted);
    }

    return null;
  }

  /**
   * Analyze user patterns to suggest optimal routes
   */
  async analyzeUserPatterns(user_id: string): Promise<UserPattern[]> {
    const query = `
      SELECT
        ur.route_number,
        ur.stop_id,
        EXTRACT(DOW FROM ah.created_at) as day,
        EXTRACT(HOUR FROM ah.created_at) as hour,
        EXTRACT(MINUTE FROM ah.created_at) as minute,
        COUNT(*) as frequency
      FROM user_routes ur
      JOIN alert_history ah ON ah.route_id = ur.id
      WHERE ur.user_id = $1
        AND ah.created_at >= NOW() - INTERVAL '60 days'
      GROUP BY ur.route_number, ur.stop_id, day, hour, minute
      HAVING COUNT(*) >= 3
      ORDER BY frequency DESC
    `;

    const result = await this.db.query(query, [user_id]);

    // Group by route and aggregate times
    const patternMap = new Map<string, UserPattern>();

    result.rows.forEach(row => {
      const key = `${row.route_number}_${row.stop_id}`;

      if (!patternMap.has(key)) {
        patternMap.set(key, {
          user_id,
          route_number: row.route_number,
          stop_id: row.stop_id,
          preferred_times: [],
          frequency_score: 0,
        });
      }

      const pattern = patternMap.get(key)!;
      pattern.preferred_times.push({
        day: row.day,
        hour: row.hour,
        minute: row.minute,
      });
      pattern.frequency_score += row.frequency;
    });

    return Array.from(patternMap.values());
  }

  /**
   * Generate smart schedule suggestions
   */
  async suggestSchedule(user_id: string): Promise<any[]> {
    const patterns = await this.analyzeUserPatterns(user_id);

    const suggestions = patterns.map(pattern => {
      // Find most common time slot
      const timeCounts = new Map<string, number>();

      pattern.preferred_times.forEach(time => {
        const key = `${time.day}_${time.hour}`;
        timeCounts.set(key, (timeCounts.get(key) || 0) + 1);
      });

      // Get top 3 most frequent times
      const topTimes = Array.from(timeCounts.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([key, count]) => {
          const [day, hour] = key.split('_').map(Number);
          return { day, hour, count };
        });

      return {
        route_number: pattern.route_number,
        stop_id: pattern.stop_id,
        suggested_times: topTimes,
        confidence: pattern.frequency_score / 10, // Normalize to 0-10
        message: `נראה שאתה משתמש בקו ${pattern.route_number} לעיתים קרובות`,
      };
    });

    return suggestions.filter(s => s.confidence >= 0.5); // Only high confidence
  }

  /**
   * Predict if user is likely to use a route today
   */
  async predictUsageToday(
    user_id: string,
    route_id: string
  ): Promise<{ likelihood: number; suggested_time?: string }> {
    const now = new Date();
    const dayOfWeek = now.getDay();
    const currentHour = now.getHours();

    const query = `
      SELECT
        EXTRACT(HOUR FROM ah.created_at) as hour,
        COUNT(*) as usage_count
      FROM alert_history ah
      JOIN user_routes ur ON ur.id = ah.route_id
      WHERE ur.id = $1
        AND ur.user_id = $2
        AND EXTRACT(DOW FROM ah.created_at) = $3
        AND ah.created_at >= NOW() - INTERVAL '60 days'
      GROUP BY hour
      ORDER BY usage_count DESC
    `;

    const result = await this.db.query(query, [route_id, user_id, dayOfWeek]);

    if (result.rows.length === 0) {
      return { likelihood: 0 };
    }

    // Calculate likelihood based on historical usage
    const totalUsage = result.rows.reduce((sum, row) => sum + row.usage_count, 0);
    const futureUsage = result.rows.filter(row => row.hour >= currentHour);

    if (futureUsage.length === 0) {
      return { likelihood: 0 };
    }

    const futureLikelihood = futureUsage.reduce((sum, row) => sum + row.usage_count, 0) / totalUsage;
    const suggestedHour = futureUsage[0].hour;

    return {
      likelihood: futureLikelihood,
      suggested_time: `${suggestedHour}:00`,
    };
  }

  /**
   * Retrain all models (should be run periodically via cron)
   */
  async retrainAllModels(): Promise<void> {
    console.log('🤖 Starting periodic model retraining...');

    // Get all unique route-stop combinations
    const query = `
      SELECT DISTINCT route_number, stop_id
      FROM user_routes
      WHERE is_active = true
    `;

    const result = await this.db.query(query);

    for (const row of result.rows) {
      try {
        await this.trainETAModel(row.route_number, row.stop_id);
      } catch (error) {
        console.error(`Failed to train model for ${row.route_number}:${row.stop_id}`, error);
      }
    }

    console.log(`✅ Retraining complete for ${result.rows.length} models`);
  }

  /**
   * Calculate model accuracy
   */
  async calculateModelAccuracy(
    route_number: string,
    stop_id: string,
    test_days: number = 7
  ): Promise<{ mae: number; rmse: number; samples: number }> {
    // Get recent data for testing
    const testData = await this.db.query(
      `
      SELECT
        EXTRACT(DOW FROM created_at) as day_of_week,
        EXTRACT(HOUR FROM created_at) as hour,
        eta_minutes as actual_eta
      FROM alert_history
      WHERE route_number = $1
        AND stop_id = $2
        AND created_at >= NOW() - INTERVAL '${test_days} days'
        AND eta_minutes IS NOT NULL
      `,
      [route_number, stop_id]
    );

    if (testData.rows.length === 0) {
      return { mae: 0, rmse: 0, samples: 0 };
    }

    let sumAbsError = 0;
    let sumSquaredError = 0;
    let validPredictions = 0;

    for (const row of testData.rows) {
      const prediction = await this.predictETA({
        route_number,
        stop_id,
        day_of_week: row.day_of_week,
        hour: row.hour,
        minute: 0,
      });

      if (prediction !== null) {
        const error = Math.abs(prediction - row.actual_eta);
        sumAbsError += error;
        sumSquaredError += error * error;
        validPredictions++;
      }
    }

    return {
      mae: sumAbsError / validPredictions,
      rmse: Math.sqrt(sumSquaredError / validPredictions),
      samples: validPredictions,
    };
  }
}
