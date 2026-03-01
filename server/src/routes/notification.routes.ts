import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import { getNotifications, markAllRead, markOneRead } from '../controllers/notification.controller';

const router = Router();

router.use(authenticate);

router.get('/', getNotifications);
router.patch('/read-all', markAllRead);
router.patch('/:id/read', markOneRead);

export default router;
