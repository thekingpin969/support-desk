import { Router } from 'express';
import { authenticate, requireRole } from '../middleware/auth.middleware';
import {
    getEmployees, createEmployee, updateEmployee, getEmployeeTickets,
    getAnalytics, getSlaConfig, updateSlaConfig, getCategories, createCategory, editCategory
} from '../controllers/admin.controller';

const router = Router();

router.use(authenticate, requireRole(['admin']));

router.get('/employees', getEmployees);
router.post('/employees', createEmployee);
router.patch('/employees/:id', updateEmployee);
router.get('/employees/:id/tickets', getEmployeeTickets);

router.get('/analytics', getAnalytics);

router.get('/sla-config', getSlaConfig);
router.put('/sla-config', updateSlaConfig);

router.get('/categories', getCategories);
router.post('/categories', createCategory);
router.patch('/categories/:id', editCategory);

export default router;
