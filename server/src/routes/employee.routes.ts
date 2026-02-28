import { Router } from 'express';
import { authenticate, requireRole } from '../middleware/auth.middleware';
import { getEmployeeDashboard } from '../controllers/employee.controller';

const router = Router();

router.use(authenticate, requireRole(['employee']));

router.get('/me/dashboard', getEmployeeDashboard);

export default router;
