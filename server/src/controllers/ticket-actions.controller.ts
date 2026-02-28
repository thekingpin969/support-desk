import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/auth.middleware';
import { assignTicket } from '../services/assignment.service';

const prisma = new PrismaClient();

export const reassignTicket = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { new_employee_id } = req.body;
        const { userId } = req.user!;

        const ticket = await prisma.ticket.findUnique({ where: { id } });
        if (!ticket) {
            res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ticket not found' } });
            return;
        }

        // Decrement open_ticket_count for old employee if it wasn't unassigned
        if (ticket.assigned_employee_id) {
            await prisma.employeeProfile.update({
                where: { user_id: ticket.assigned_employee_id },
                data: { open_ticket_count: { decrement: 1 } }
            });
        }

        // If new_employee_id is provided, explicitly assign. Otherwise run automatic assignment.
        if (new_employee_id) {
            await prisma.$transaction([
                prisma.ticket.update({
                    where: { id },
                    data: {
                        assigned_employee_id: new_employee_id,
                        status: 'reassigned',
                    }
                }),
                prisma.employeeProfile.update({
                    where: { user_id: new_employee_id },
                    data: {
                        open_ticket_count: { increment: 1 },
                        last_assigned_at: new Date()
                    }
                }),
                prisma.ticketAuditLog.create({
                    data: {
                        ticket_id: id,
                        from_status: ticket.status,
                        to_status: 'reassigned',
                        actor_id: userId,
                        note: `Admin reassigned to explicit employee`
                    }
                })
            ]);
        } else {
            await assignTicket(id);
        }

        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const escalateNotify = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;

        // In a real scenario, this would trigger an urgent push notification via Firebase Admin.
        // We can simulate it by creating an in-app notification.
        const ticket = await prisma.ticket.findUnique({ where: { id } });
        if (!ticket || ticket.status !== 'escalated' || !ticket.assigned_employee_id) {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Ticket cannot be escalate-notified' } });
            return;
        }

        await prisma.notification.create({
            data: {
                user_id: ticket.assigned_employee_id,
                type: 'URGENT_ESCALATION',
                message: `URGENT: Your assigned ticket ${ticket.ticket_number} has breached SLA. Action required immediately.`,
            }
        });

        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const reopenTicket = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { userId } = req.user!;

        const ticket = await prisma.ticket.findUnique({ where: { id } });
        if (!ticket || ticket.client_id !== userId) {
            res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ticket not found' } });
            return;
        }

        if (ticket.status !== 'closed' && ticket.status !== 'resolved') {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Ticket must be closed or resolved to reopen' } });
            return;
        }

        if (ticket.reopen_count >= 1) {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Ticket has already been reopened the maximum number of times' } });
            return;
        }

        await prisma.$transaction([
            prisma.ticket.update({
                where: { id },
                data: {
                    status: 'reopened',
                    reopen_count: { increment: 1 }
                }
            }),
            prisma.ticketAuditLog.create({
                data: {
                    ticket_id: id,
                    from_status: ticket.status,
                    to_status: 'reopened',
                    actor_id: userId,
                    note: `Client reopened ticket`
                }
            })
        ]);

        await assignTicket(id);

        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const rateTicket = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { userId } = req.user!;
        const { rating, rating_comment } = req.body;

        const ticket = await prisma.ticket.findUnique({ where: { id } });
        if (!ticket || ticket.client_id !== userId) {
            res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ticket not found' } });
            return;
        }

        if (ticket.status !== 'resolved' && ticket.status !== 'closed') {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Ticket must be resolved to rate' } });
            return;
        }

        await prisma.$transaction([
            prisma.ticket.update({
                where: { id },
                data: {
                    rating,
                    rating_comment,
                    status: 'closed',
                    closed_at: ticket.closed_at ?? new Date()
                }
            }),
            prisma.ticketAuditLog.create({
                data: {
                    ticket_id: id,
                    from_status: ticket.status,
                    to_status: 'closed',
                    actor_id: userId,
                    note: `Client rated ticket: ${rating} stars`
                }
            })
        ]);

        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};
