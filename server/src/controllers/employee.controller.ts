import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/auth.middleware';

const prisma = new PrismaClient();

export const getEmployeeDashboard = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { userId } = req.user!;

        const profile = await prisma.employeeProfile.findUnique({ where: { user_id: userId } });
        const user = await prisma.user.findUnique({ where: { id: userId } });

        // Active tickets (assigned, in_progress, revision_requested)
        const activeTickets = await prisma.ticket.findMany({
            where: {
                assigned_employee_id: userId,
                status: { in: ['assigned', 'in_progress', 'revision_requested'] }
            },
            orderBy: { sla_deadline: 'asc' },
            include: {
                category: true,
            }
        });

        // Historical tickets (closed, resolved)
        const closedTickets = await prisma.ticket.findMany({
            where: {
                assigned_employee_id: userId,
                status: { in: ['closed', 'resolved'] }
            },
            orderBy: { updated_at: 'desc' },
            take: 20, // paginated in real app
            include: {
                category: true,
            }
        });

        const metrics = {
            open_ticket_count: profile?.open_ticket_count || 0,
            max_capacity: profile?.max_capacity || 10,
        };

        res.status(200).json({
            status: 'success',
            data: {
                user: { name: user?.full_name, email: user?.email, department: profile?.department },
                metrics,
                active_tickets: activeTickets,
                closed_tickets: closedTickets,
            }
        });

    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};
