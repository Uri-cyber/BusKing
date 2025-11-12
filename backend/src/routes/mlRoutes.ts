import express, { Request, Response } from 'express';
import { MLService } from '../services/mlService';
import { authenticate } from '../middleware/auth';
import { body, query, validationResult } from 'express-validator';

const router = express.Router();

/**
 * POST /api/v1/ml/train
 * Train ETA prediction model for a specific route
 */
router.post(
  '/train',
  authenticate,
  [
    body('route_number').isString().notEmpty(),
    body('stop_id').isString().notEmpty(),
  ],
  async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    try {
      const { route_number, stop_id } = req.body;
      const mlService: MLService = req.app.get('mlService');

      await mlService.trainETAModel(route_number, stop_id);

      res.json({
        success: true,
        message: 'Model training initiated',
        data: {
          route_number,
          stop_id,
        },
      });
    } catch (error: any) {
      console.error('Train model error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to train model',
        error: error.message,
      });
    }
  }
);

/**
 * GET /api/v1/ml/predict-eta
 * Get ML-based ETA prediction
 */
router.get(
  '/predict-eta',
  authenticate,
  [
    query('route_number').isString().notEmpty(),
    query('stop_id').isString().notEmpty(),
    query('day_of_week').optional().isInt({ min: 0, max: 6 }),
    query('hour').optional().isInt({ min: 0, max: 23 }),
  ],
  async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    try {
      const { route_number, stop_id, day_of_week, hour } = req.query;
      const mlService: MLService = req.app.get('mlService');

      const now = new Date();
      const prediction = await mlService.predictETA({
        route_number: route_number as string,
        stop_id: stop_id as string,
        day_of_week: day_of_week ? parseInt(day_of_week as string) : now.getDay(),
        hour: hour ? parseInt(hour as string) : now.getHours(),
        minute: now.getMinutes(),
      });

      if (prediction === null) {
        return res.json({
          success: true,
          message: 'Not enough data for prediction',
          data: {
            predicted_eta: null,
            confidence: 'low',
          },
        });
      }

      res.json({
        success: true,
        data: {
          predicted_eta: prediction,
          confidence: 'medium',
          route_number,
          stop_id,
        },
      });
    } catch (error: any) {
      console.error('Predict ETA error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to predict ETA',
        error: error.message,
      });
    }
  }
);

/**
 * GET /api/v1/ml/patterns
 * Get user's usage patterns and suggestions
 */
router.get(
  '/patterns',
  authenticate,
  async (req: Request, res: Response) => {
    try {
      const user_id = (req as any).user.id;
      const mlService: MLService = req.app.get('mlService');

      const patterns = await mlService.analyzeUserPatterns(user_id);

      res.json({
        success: true,
        data: {
          patterns,
          count: patterns.length,
        },
      });
    } catch (error: any) {
      console.error('Analyze patterns error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to analyze patterns',
        error: error.message,
      });
    }
  }
);

/**
 * GET /api/v1/ml/suggestions
 * Get smart schedule suggestions based on ML
 */
router.get(
  '/suggestions',
  authenticate,
  async (req: Request, res: Response) => {
    try {
      const user_id = (req as any).user.id;
      const mlService: MLService = req.app.get('mlService');

      const suggestions = await mlService.suggestSchedule(user_id);

      res.json({
        success: true,
        data: {
          suggestions,
          count: suggestions.length,
          message: suggestions.length > 0
            ? 'מצאנו המלצות בשבילך'
            : 'אין מספיק נתונים להמלצות',
        },
      });
    } catch (error: any) {
      console.error('Get suggestions error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get suggestions',
        error: error.message,
      });
    }
  }
);

/**
 * GET /api/v1/ml/usage-prediction
 * Predict if user will use a route today
 */
router.get(
  '/usage-prediction/:route_id',
  authenticate,
  async (req: Request, res: Response) => {
    try {
      const { route_id } = req.params;
      const user_id = (req as any).user.id;
      const mlService: MLService = req.app.get('mlService');

      const prediction = await mlService.predictUsageToday(user_id, route_id);

      res.json({
        success: true,
        data: {
          route_id,
          likelihood: prediction.likelihood,
          suggested_time: prediction.suggested_time,
          recommendation: prediction.likelihood > 0.7
            ? 'מומלץ להפעיל התרעות לקו זה'
            : prediction.likelihood > 0.3
            ? 'ייתכן שתשתמש בקו זה היום'
            : 'לא צפוי שימוש בקו זה היום',
        },
      });
    } catch (error: any) {
      console.error('Predict usage error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to predict usage',
        error: error.message,
      });
    }
  }
);

/**
 * GET /api/v1/ml/model-accuracy/:route_number/:stop_id
 * Get model accuracy metrics (admin only)
 */
router.get(
  '/model-accuracy/:route_number/:stop_id',
  authenticate,
  async (req: Request, res: Response) => {
    try {
      const { route_number, stop_id } = req.params;
      const mlService: MLService = req.app.get('mlService');

      const accuracy = await mlService.calculateModelAccuracy(route_number, stop_id);

      res.json({
        success: true,
        data: {
          route_number,
          stop_id,
          mae: accuracy.mae.toFixed(2),
          rmse: accuracy.rmse.toFixed(2),
          samples: accuracy.samples,
          quality: accuracy.mae < 2 ? 'excellent' : accuracy.mae < 5 ? 'good' : 'fair',
        },
      });
    } catch (error: any) {
      console.error('Get accuracy error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get model accuracy',
        error: error.message,
      });
    }
  }
);

/**
 * POST /api/v1/ml/retrain-all
 * Retrain all models (admin only, typically called by cron)
 */
router.post(
  '/retrain-all',
  authenticate,
  async (req: Request, res: Response) => {
    try {
      const mlService: MLService = req.app.get('mlService');

      // Run retraining asynchronously
      mlService.retrainAllModels().catch(error => {
        console.error('Background retraining error:', error);
      });

      res.json({
        success: true,
        message: 'Model retraining initiated in background',
      });
    } catch (error: any) {
      console.error('Retrain all error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to initiate retraining',
        error: error.message,
      });
    }
  }
);

export default router;
