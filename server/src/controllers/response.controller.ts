import { Request, Response } from 'express';
import { PrismaClient, TicketStatus, ResponseStatus } from '@prisma/client';
import { AuthRequest } from '../middleware/auth.middleware';
import { z } from 'zod';

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
            await prisma.$transaction([
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
            await prisma.$transaction([
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

        const response = await prisma.ticketResponse.findUnique({ where: { id: rid } });
        if (!response || response.status !== 'pending_review' || response.ticket_id !== id) {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Invalid response or not pending review' } });
            return;
        }

        await prisma.$transaction([
            prisma.ticketResponse.update({
                where: { id: rid },
                data: {
                    status: 'approved',
                    reviewed_by: userId,
                    reviewed_at: new Date()
                }
            }),
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
                    note: 'Admin approved response'
                }
            }),
        ]);

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

        const response = await prisma.ticketResponse.findUnique({ where: { id: rid } });
        if (!response || response.status !== 'pending_review' || response.ticket_id !== id) {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Invalid response or not pending review' } });
            return;
        }

        await prisma.$transaction([
            prisma.ticketResponse.update({
                where: { id: rid },
                data: {
                    status: 'rejected',
                    admin_feedback: feedback,
                    reviewed_by: userId,
                    reviewed_at: new Date()
                }
            }),
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
                    note: `Admin rejected response`
                }
            })
        ]);

        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};
