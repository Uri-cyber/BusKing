import cron from 'node-cron';
import { MLService } from './mlService';

export class MLCronService {
  private mlService: MLService;

  constructor(mlService: MLService) {
    this.mlService = mlService;
  }

  /**
   * Start all ML-related cron jobs
   */
  start(): void {
    console.log('🤖 Starting ML cron jobs...');

    // Retrain models daily at 2 AM
    cron.schedule('0 2 * * *', async () => {
      console.log('🔄 Running daily model retraining...');
      try {
        await this.mlService.retrainAllModels();
        console.log('✅ Daily model retraining completed');
      } catch (error) {
        console.error('❌ Daily model retraining failed:', error);
      }
    });

    // Clean up old training data weekly (Sunday at 3 AM)
    cron.schedule('0 3 * * 0', async () => {
      console.log('🧹 Running weekly data cleanup...');
      try {
        await this.cleanupOldData();
        console.log('✅ Weekly data cleanup completed');
      } catch (error) {
        console.error('❌ Weekly data cleanup failed:', error);
      }
    });

    // Generate usage insights daily at 6 AM
    cron.schedule('0 6 * * *', async () => {
      console.log('📊 Generating daily usage insights...');
      try {
        await this.generateUsageInsights();
        console.log('✅ Daily usage insights generated');
      } catch (error) {
        console.error('❌ Usage insights generation failed:', error);
      }
    });

    console.log('✅ ML cron jobs started');
  }

  /**
   * Clean up training data older than 90 days
   */
  private async cleanupOldData(): Promise<void> {
    // This would be implemented based on your data retention policy
    console.log('Cleaning up data older than 90 days...');
    // Implementation here
  }

  /**
   * Generate usage insights for all users
   */
  private async generateUsageInsights(): Promise<void> {
    console.log('Generating usage insights...');
    // This could send personalized notifications about usage patterns
    // Implementation here
  }
}
