import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import { getNotifications, markAllRead } from '../controllers/notification.controller';

const router = Router();

router.use(authenticate);

router.get('/', getNotifications);
router.patch('/read-all', markAllRead);

export default router;
