import { Request, Response } from 'express';
import { PrismaClient, TicketStatus, ResponseStatus } from '@prisma/client';
import { AuthRequest } from '../middleware/auth.middleware';
import { z } from 'zod';
import { sendNotification } from '../services/notification.service';

const prisma = new PrismaClient();

const submitResponseSchema = z.object({
    response_text: z.string().min(1),
    status: z.enum(['draft', 'pending_review']),
});

export const updateResponse = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id, rid } = req.params;
        const { userId } = req.user!;
        const data = submitResponseSchema.parse(req.body);

        const isPendingReview = data.status === 'pending_review';

        let response = await prisma.ticketResponse.findUnique({ where: { id: rid } });
        if (!response) {
            response = await prisma.ticketResponse.create({
                data: {
                    id: rid,
                    ticket_id: id,
                    employee_id: userId,
                    response_text: data.response_text,
                    status: data.status,
                    submitted_at: isPendingReview ? new Date() : null,
                }
            });
        } else {
            if (response.status === 'pending_review' || response.status === 'approved') {
                res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Response already submitted or approved' } });
                return;
            }

            response = await prisma.ticketResponse.update({
                where: { id: rid },
                data: {
                    response_text: data.response_text,
                    status: data.status,
                    submitted_at: isPendingReview ? new Date() : null,
                }
            });
        }

        if (isPendingReview) {
            const [ticket] = await prisma.$transaction([
                prisma.ticket.update({
                    where: { id },
                    data: { status: 'pending_review' },
                }),
                prisma.ticketAuditLog.create({
                    data: {
                        ticket_id: id,
                        from_status: null,
                        to_status: 'pending_review',
                        actor_id: userId,
                        note: 'Employee submitted response for review'
                    }
                }),
            ]);

            const admins = await prisma.user.findMany({ where: { role: 'admin' } });
            for (const admin of admins) {
                await sendNotification(admin.id, 'Response Pending Review', `Ticket ${ticket.ticket_number} has a response waiting for review.`);
            }
        }

        res.status(200).json({ status: 'success', response });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const createNewResponse = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { userId } = req.user!;
        const data = submitResponseSchema.parse(req.body);

        const isPendingReview = data.status === 'pending_review';

        const response = await prisma.ticketResponse.create({
            data: {
                ticket_id: id,
                employee_id: userId,
                response_text: data.response_text,
                status: data.status,
                submitted_at: isPendingReview ? new Date() : null,
            }
        });

        if (isPendingReview) {
            const [ticket] = await prisma.$transaction([
                prisma.ticket.update({
                    where: { id },
                    data: { status: 'pending_review' },
                }),
                prisma.ticketAuditLog.create({
                    data: {
                        ticket_id: id,
                        from_status: null,
                        to_status: 'pending_review',
                        actor_id: userId,
                        note: 'Employee submitted new response for review'
                    }
                })
            ]);

            const admins = await prisma.user.findMany({ where: { role: 'admin' } });
            for (const admin of admins) {
                await sendNotification(admin.id, 'Response Pending Review', `Ticket ${ticket.ticket_number} has a new response waiting for review.`);
            }
        }

        res.status(200).json({ status: 'success', response });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const approveResponse = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id, rid } = req.params;
        const { userId } = req.user!;

        const updateResult = await prisma.ticketResponse.updateMany({
            where: { id: rid, status: 'pending_review', ticket_id: id },
            data: {
                status: 'approved',
                reviewed_by: userId,
                reviewed_at: new Date()
            }
        });

        if (updateResult.count === 0) {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Invalid response or already actioned' } });
            return;
        }

        const [ticket] = await prisma.$transaction([
            prisma.ticket.update({
                where: { id },
                data: {
                    status: 'resolved',
                    resolved_at: new Date()
                }
            }),
            prisma.ticketAuditLog.create({
                data: {
                    ticket_id: id,
                    from_status: 'pending_review',
                    to_status: 'resolved',
                    actor_id: userId,
                    note: 'Admin approved response — ticket resolved and sent to client'
                }
            }),
        ]);

        const response = await prisma.ticketResponse.findUnique({ where: { id: rid } });
        if (response) {
            await sendNotification(response.employee_id, 'Response Approved ✅', `Your response for ticket ${ticket.ticket_number} was approved by the admin and sent to the client.`);
        }
        await sendNotification(ticket.client_id, 'Ticket Resolved ✅', `Your support ticket ${ticket.ticket_number} has been resolved. Open the ticket to view the official response from our support team.`);

        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const rejectResponse = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id, rid } = req.params;
        const { userId } = req.user!;
        const { feedback } = req.body;

        if (!feedback) {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Feedback is required' } });
            return;
        }

        const updateResult = await prisma.ticketResponse.updateMany({
            where: { id: rid, status: 'pending_review', ticket_id: id },
            data: {
                status: 'rejected',
                admin_feedback: feedback,
                reviewed_by: userId,
                reviewed_at: new Date()
            }
        });

        if (updateResult.count === 0) {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Invalid response or already actioned' } });
            return;
        }

        const [ticket] = await prisma.$transaction([
            prisma.ticket.update({
                where: { id },
                data: {
                    status: 'revision_requested'
                }
            }),
            prisma.ticketAuditLog.create({
                data: {
                    ticket_id: id,
                    from_status: 'pending_review',
                    to_status: 'revision_requested',
                    actor_id: userId,
                    note: `Admin requested revision — employee must revise and resubmit`
                }
            })
        ]);

        const response = await prisma.ticketResponse.findUnique({ where: { id: rid } });
        if (response) {
            await sendNotification(response.employee_id, 'Revision Requested 🔄', `The admin has requested a revision for your response on ticket ${ticket.ticket_number}. Revision instructions: ${feedback}`);
        }

        // GAP 6: Flag tickets with 3+ rejections — suggest reassignment to admin
        const rejectionCount = await prisma.ticketResponse.count({
            where: { ticket_id: id, status: 'rejected' }
        });
        if (rejectionCount >= 3) {
            const admins = await prisma.user.findMany({ where: { role: 'admin' } });
            for (const admin of admins) {
                await sendNotification(admin.id, 'Multiple Revisions Required ⚠️', `Ticket ${ticket.ticket_number} has had ${rejectionCount} revision requests. Consider reassigning this ticket to a different employee.`);
            }
        }

        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};
