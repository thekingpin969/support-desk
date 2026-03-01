import { Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/auth.middleware';

const prisma = new PrismaClient();

// Default SLA warning hours per priority (fallback)
const DEFAULT_WARNING: Record<string, number> = { critical: 1, high: 2, medium: 4, low: 12 };

export const getEmployeeDashboard = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { userId } = req.user!;
        const now = new Date();

        const profile = await prisma.employeeProfile.findUnique({ where: { user_id: userId } });
        const user = await prisma.user.findUnique({ where: { id: userId } });

        // Active tickets (assigned, in_progress, revision_requested, escalated, reassigned, pending_review)
        const activeTickets = await prisma.ticket.findMany({
            where: {
                assigned_employee_id: userId,
                status: { in: ['assigned', 'in_progress', 'revision_requested', 'escalated', 'reassigned', 'pending_review'] }
            },
            orderBy: { sla_deadline: 'asc' },
            include: {
                category: true,
                images: true,
                responses: {
                    include: { employee: { select: { full_name: true } } },
                    orderBy: { created_at: 'asc' }
                }
            }
        });

        // Historical tickets (closed, resolved) — last 50, paginated
        const closedTickets = await prisma.ticket.findMany({
            where: {
                assigned_employee_id: userId,
                status: { in: ['closed', 'resolved'] }
            },
            orderBy: { updated_at: 'desc' },
            take: 50,
            include: {
                category: true,
                images: true,
                responses: {
                    include: { employee: { select: { full_name: true } } },
                    orderBy: { created_at: 'asc' }
                }
            }
        });

        // Resolved tickets for SLA compliance (resolved_at exists)
        const resolvedForSla = await prisma.ticket.findMany({
            where: { assigned_employee_id: userId, status: { in: ['resolved', 'closed'] }, resolved_at: { not: null } },
            select: { sla_deadline: true, resolved_at: true, created_at: true }
        });

        const resolvedBeforeSla = resolvedForSla.filter(t =>
            t.sla_deadline && t.resolved_at && t.resolved_at <= t.sla_deadline
        );
        const sla_compliance_rate = resolvedForSla.length > 0
            ? Math.round((resolvedBeforeSla.length / resolvedForSla.length) * 100)
            : 100;

        // Avg response time in hours (ticket creation → resolution)
        const avg_response_time_hours = resolvedForSla.length > 0
            ? Math.round(
                resolvedForSla.reduce((sum, t) =>
                    sum + (t.resolved_at!.getTime() - t.created_at.getTime()), 0
                ) / resolvedForSla.length / (1000 * 60 * 60)
            )
            : 0;

        // Escalated count
        const escalated_count = activeTickets.filter(t => t.status === 'escalated').length;

        // Warning count: active, approaching SLA but not yet breached
        const slaConfigs = await prisma.slaConfig.findMany();
        const configMap = new Map(slaConfigs.map(c => [c.priority, c]));
        const warning_count = activeTickets.filter(t => {
            if (!t.sla_deadline || t.status === 'escalated') return false;
            const cfg = configMap.get(t.priority);
            const warningHours = cfg ? cfg.warning_hours : (DEFAULT_WARNING[t.priority] ?? 2);
            const warningTime = new Date(t.sla_deadline.getTime() - warningHours * 60 * 60 * 1000);
            return now >= warningTime && t.sla_deadline > now;
        }).length;

        // Unread notification count
        const unread_notification_count = await prisma.notification.count({
            where: { user_id: userId, is_read: false }
        });

        const metrics = {
            open_ticket_count: profile?.open_ticket_count || 0,
            max_capacity: profile?.max_capacity || 10,
            sla_compliance_rate,
            avg_response_time_hours,
            escalated_count,
            warning_count,
            unread_notification_count,
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
