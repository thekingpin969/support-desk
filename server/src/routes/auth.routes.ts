import { Router } from 'express';
import { registerClient, login, refresh, logout, forgotPassword, resetPassword } from '../controllers/auth.controller';

const router = Router();

router.post('/:role/register', registerClient);
router.post('/:role/login', login);
router.post('/refresh', refresh);
router.post('/logout', logout);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

export default router;
