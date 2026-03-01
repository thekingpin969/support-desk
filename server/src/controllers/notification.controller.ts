import { Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/auth.middleware';

const prisma = new PrismaClient();

export const getNotifications = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { userId } = req.user!;
        // Paginated or limit 50
        const notifications = await prisma.notification.findMany({
            where: { user_id: userId },
            orderBy: { created_at: 'desc' },
            take: 50
        });
        const unread_count = await prisma.notification.count({ where: { user_id: userId, is_read: false } });
        res.status(200).json({ status: 'success', notifications, unread_count });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const markAllRead = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { userId } = req.user!;
        await prisma.notification.updateMany({
            where: { user_id: userId, is_read: false },
            data: { is_read: true }
        });
        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const markOneRead = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { userId } = req.user!;
        const { id } = req.params;
        const notification = await prisma.notification.findUnique({ where: { id } });
        if (!notification || notification.user_id !== userId) {
            res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Notification not found' } });
            return;
        }
        await prisma.notification.update({ where: { id }, data: { is_read: true } });
        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

