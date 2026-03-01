import { Router } from 'express';
import multer from 'multer';
import { authenticate, requireRole } from '../middleware/auth.middleware';
import { uploadImageObj } from '../controllers/upload.controller';

const router = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } }); // 10MB

router.use(authenticate);

// We allow clients and employees to upload attachments
router.post('/', requireRole(['client', 'employee']), upload.single('image'), uploadImageObj);

export default router;
