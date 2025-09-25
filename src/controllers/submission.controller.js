import { db } from '#config/database.js';
import { submissions } from '#models/submission.model.js';
import { desc, sql } from 'drizzle-orm';
import { logger } from '#config/logger.js';

/**
 * Submit new text entry
 * POST /api/submissions
 */
export const createSubmission = async (req, res) => {
  try {
    const { text } = req.body;

    // Validate input
    if (!text || typeof text !== 'string' || text.trim().length === 0) {
      return res.status(400).json({
        error: 'Text is required and cannot be empty'
      });
    }

    // Limit text length for security
    if (text.length > 1000) {
      return res.status(400).json({
        error: 'Text cannot exceed 1000 characters'
      });
    }

    // Insert submission
    const [submission] = await db
      .insert(submissions)
      .values({
        text: text.trim()
      })
      .returning();

    logger.info('New submission created', { submissionId: submission.id });

    res.status(201).json({
      message: 'Submission created successfully',
      submission: {
        id: submission.id,
        text: submission.text,
        created_at: submission.createdAt
      }
    });

  } catch (error) {
    logger.error('Error creating submission:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
};

/**
 * Get last 5 submissions
 * GET /api/submissions
 */
export const getLastSubmissions = async (req, res) => {
  try {
    // Get last 5 submissions ordered by creation date (newest first)
    const lastSubmissions = await db
      .select({
        id: submissions.id,
        text: submissions.text,
        created_at: submissions.createdAt
      })
      .from(submissions)
      .orderBy(desc(submissions.createdAt))
      .limit(5);

    logger.info('Retrieved last submissions', { count: lastSubmissions.length });

    res.json(lastSubmissions);

  } catch (error) {
    logger.error('Error fetching submissions:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
};

/**
 * Get submission statistics (for monitoring)
 * GET /api/submissions/stats
 */
export const getSubmissionStats = async (req, res) => {
  try {
    const [stats] = await db
      .select({
        total: sql`count(*)`,
        today: sql`count(*) filter (where date(created_at) = current_date)`,
        last_24h: sql`count(*) filter (where created_at >= now() - interval '24 hours')`
      })
      .from(submissions);

    res.json(stats);

  } catch (error) {
    logger.error('Error fetching submission stats:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
};