# BusAlert Machine Learning Guide

## Overview

BusAlert uses Machine Learning to enhance user experience through predictive analytics and personalized suggestions. The ML system learns from historical data to provide accurate ETA predictions, recognize user patterns, and suggest optimal schedules.

## Features

### 1. **ETA Prediction** 🎯
- Predicts bus arrival times based on historical data
- Considers time of day, day of week, weather, and traffic
- Continuously improves with more data
- Provides confidence scores

### 2. **User Pattern Recognition** 📊
- Analyzes user behavior over time
- Identifies frequently used routes
- Detects preferred travel times
- Recognizes regular patterns

### 3. **Smart Scheduling** 🗓️
- Suggests optimal times for route activation
- Predicts likelihood of route usage
- Provides personalized recommendations
- Learns from user feedback

### 4. **Adaptive Alerts** ⚡
- Adjusts alert timing based on learned patterns
- Considers historical accuracy
- Personalizes notification preferences
- Reduces false positives

## Technical Architecture

### Model Types

#### 1. Time-Series ETA Prediction
```
Input: route_number, stop_id, day_of_week, hour, weather, traffic
Output: predicted_eta_minutes

Algorithm: Statistical averaging with time-slot grouping
- Groups data by day_of_week and hour
- Calculates weighted averages
- Applies contextual adjustments (weather, traffic)
```

#### 2. Pattern Recognition
```
Input: user_id, historical_usage_data
Output: usage_patterns, frequency_scores

Algorithm: Frequency analysis
- Aggregates usage by route and time slots
- Identifies recurring patterns
- Scores by frequency and recency
```

#### 3. Usage Prediction
```
Input: user_id, route_id, current_time
Output: likelihood_score, suggested_time

Algorithm: Probabilistic prediction
- Analyzes historical usage for similar time slots
- Calculates probability based on past behavior
- Suggests most likely usage times
```

## API Endpoints

### Train Model
```bash
POST /api/v1/ml/train
Authorization: Bearer <token>

Body:
{
  "route_number": "5",
  "stop_id": "12345"
}

Response:
{
  "success": true,
  "message": "Model training initiated"
}
```

### Predict ETA
```bash
GET /api/v1/ml/predict-eta?route_number=5&stop_id=12345
Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "predicted_eta": 12,
    "confidence": "medium",
    "route_number": "5",
    "stop_id": "12345"
  }
}
```

### Get User Patterns
```bash
GET /api/v1/ml/patterns
Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "patterns": [
      {
        "route_number": "5",
        "stop_id": "12345",
        "preferred_times": [
          { "day": 1, "hour": 8, "minute": 30 },
          { "day": 2, "hour": 8, "minute": 25 }
        ],
        "frequency_score": 45
      }
    ],
    "count": 1
  }
}
```

### Get Smart Suggestions
```bash
GET /api/v1/ml/suggestions
Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "suggestions": [
      {
        "route_number": "5",
        "stop_id": "12345",
        "suggested_times": [
          { "day": 1, "hour": 8, "count": 15 }
        ],
        "confidence": 8.5,
        "message": "נראה שאתה משתמש בקו 5 לעיתים קרובות"
      }
    ],
    "count": 1
  }
}
```

### Predict Usage Today
```bash
GET /api/v1/ml/usage-prediction/:route_id
Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "route_id": "abc123",
    "likelihood": 0.85,
    "suggested_time": "8:00",
    "recommendation": "מומלץ להפעיל התרעות לקו זה"
  }
}
```

## Data Requirements

### Minimum Training Data
- **ETA Prediction**: 10+ historical alerts per route-stop
- **Pattern Recognition**: 3+ occurrences of similar patterns
- **Usage Prediction**: 30+ days of historical data

### Data Quality
- Clean, validated data
- Accurate timestamps
- Correct ETA measurements
- Consistent route/stop IDs

## Model Training

### Initial Training
Models are trained automatically when:
1. First prediction request is made
2. Sufficient historical data exists (10+ samples)
3. Periodic retraining triggers

### Periodic Retraining
- **Frequency**: Daily at 2 AM (configurable)
- **Trigger**: Cron job via `MLCronService`
- **Scope**: All active route-stop combinations

### Manual Training
```bash
POST /api/v1/ml/train
{
  "route_number": "5",
  "stop_id": "12345"
}
```

## Model Evaluation

### Accuracy Metrics

#### MAE (Mean Absolute Error)
Average difference between predicted and actual ETA:
- **Excellent**: < 2 minutes
- **Good**: 2-5 minutes
- **Fair**: 5-10 minutes
- **Poor**: > 10 minutes

#### RMSE (Root Mean Squared Error)
Penalizes larger errors more heavily:
- Lower is better
- Should be < 1.5x MAE

### Checking Accuracy
```bash
GET /api/v1/ml/model-accuracy/:route_number/:stop_id

Response:
{
  "success": true,
  "data": {
    "route_number": "5",
    "stop_id": "12345",
    "mae": "2.45",
    "rmse": "3.12",
    "samples": 150,
    "quality": "good"
  }
}
```

## Performance Optimization

### Caching
- Models cached in Redis (24 hours)
- In-memory cache for hot models
- Lazy loading on first request

### Scalability
- Stateless design allows horizontal scaling
- Models stored in distributed cache
- Batch training for efficiency

## Future Enhancements

### Phase 2: Advanced ML
- [ ] TensorFlow.js integration
- [ ] LSTM for time-series prediction
- [ ] Real-time model updates
- [ ] A/B testing framework

### Phase 3: Deep Learning
- [ ] Neural networks for complex patterns
- [ ] Multi-factor predictions
- [ ] Ensemble methods
- [ ] Transfer learning

### Phase 4: Personalization
- [ ] User-specific models
- [ ] Behavioral clustering
- [ ] Collaborative filtering
- [ ] Contextual awareness

## Best Practices

### For Developers

1. **Always check data availability** before making predictions
2. **Handle null predictions** gracefully
3. **Cache predictions** when appropriate
4. **Monitor model accuracy** regularly
5. **Log prediction errors** for debugging

### For Operations

1. **Monitor cron job execution**
2. **Set up alerts for training failures**
3. **Review accuracy metrics weekly**
4. **Scale Redis for model storage**
5. **Backup training data regularly**

## Troubleshooting

### Low Accuracy
**Problem**: MAE > 5 minutes

**Solutions**:
- Check data quality
- Increase training data
- Verify time zone handling
- Review feature engineering

### No Predictions
**Problem**: `predicted_eta: null`

**Solutions**:
- Ensure minimum 10 samples exist
- Check database connectivity
- Verify route/stop IDs are correct
- Review training logs

### Slow Predictions
**Problem**: API response > 2 seconds

**Solutions**:
- Enable Redis caching
- Optimize database queries
- Use connection pooling
- Pre-train popular routes

## Configuration

### Environment Variables
```bash
# ML Settings
ML_MIN_TRAINING_SAMPLES=10
ML_CACHE_TTL=86400
ML_RETRAIN_CRON="0 2 * * *"
ML_DATA_RETENTION_DAYS=90
ML_CONFIDENCE_THRESHOLD=0.5
```

### Database Indexes
```sql
-- Index for training data queries
CREATE INDEX idx_alert_history_ml ON alert_history(
  route_number, stop_id, created_at
) WHERE alert_type = 'initial';

-- Index for pattern analysis
CREATE INDEX idx_alert_history_patterns ON alert_history(
  route_id, created_at
);
```

## Monitoring

### Key Metrics
- Model training frequency
- Prediction request rate
- Average MAE/RMSE per route
- Cache hit ratio
- Training duration

### Alerts
- Training failures > 3 consecutive days
- MAE degradation > 50%
- Low cache hit ratio < 70%
- Training duration > 1 hour

## Privacy & Ethics

### Data Privacy
- Personal data anonymized
- Aggregate patterns only
- GDPR compliant
- User consent required

### Ethical Considerations
- Transparent predictions
- Explainable results
- Fair treatment of all users
- No discriminatory patterns

## References

- [Time Series Analysis](https://en.wikipedia.org/wiki/Time_series)
- [Pattern Recognition](https://en.wikipedia.org/wiki/Pattern_recognition)
- [MAE vs RMSE](https://medium.com/human-in-a-machine-world/mae-and-rmse-which-metric-is-better-e60ac3bde13d)
- [ML Best Practices](https://developers.google.com/machine-learning/guides/rules-of-ml)

---

**Last Updated**: 2025-01-12
**Version**: 1.0.0
**Maintained by**: BusAlert ML Team
