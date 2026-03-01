import { Request, Response } from 'express';
import { PrismaClient, Priority, TicketStatus } from '@prisma/client';
import { AuthRequest } from '../middleware/auth.middleware';
import { z } from 'zod';
import { assignTicket } from '../services/assignment.service';
import axios from 'axios';

const prisma = new PrismaClient();

// Default SLA hours per priority (fallback if sla_configs table is empty)
const DEFAULT_SLA_HOURS: Record<string, number> = {
    critical: 2,
    high: 8,
    medium: 24,
    low: 72,
};

const createTicketSchema = z.object({
    title: z.string().min(1),
    description: z.string().min(1),
    category_id: z.string().uuid(),
    priority: z.enum(['low', 'medium', 'high', 'critical']),
    images: z.array(z.object({
        imgbb_url: z.string().url(),
        imgbb_delete_url: z.string().url()
    })).optional()
});

async function calculateSlaDeadline(priority: string): Promise<Date> {
    const date = new Date();
    // Try to read from DB config first
    const config = await prisma.slaConfig.findFirst({ where: { priority: priority as any } });
    const hours = config ? config.response_hours : (DEFAULT_SLA_HOURS[priority] ?? 24);
    date.setTime(date.getTime() + hours * 60 * 60 * 1000);
    return date;
}

export const createTicket = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const data = createTicketSchema.parse(req.body);
        const userId = req.user!.userId;

        const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const countToday = await prisma.ticket.count({
            where: { ticket_number: { startsWith: `TKT-${today}` } }
        });
        const seq = String(countToday + 1).padStart(4, '0');
        const ticketNumber = `TKT-${today}-${seq}`;

        const sla_deadline = await calculateSlaDeadline(data.priority);

        const ticket = await prisma.ticket.create({
            data: {
                title: data.title,
                description: data.description,
                priority: data.priority as Priority,
                status: 'open',
                category_id: data.category_id,
                client_id: userId,
                ticket_number: ticketNumber,
                sla_deadline,
                images: {
                    create: data.images?.map((img: { imgbb_url: string, imgbb_delete_url: string }) => ({
                        imgbb_url: img.imgbb_url,
                        imgbb_delete_url: img.imgbb_delete_url,
                        uploaded_by: userId,
                        context: 'ticket'
                    })) || []
                }
            },
            include: {
                images: true
            }
        });

        await prisma.ticketAuditLog.create({
            data: {
                ticket_id: ticket.id,
                to_status: 'open',
                actor_id: userId,
                note: 'Ticket created',
            }
        });

        // Run assignment engine
        const assignedUser = await assignTicket(ticket.id);

        res.status(201).json({
            status: 'success',
            ticket,
            assigned: assignedUser != null
        });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const getTickets = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { role, userId } = req.user!;
        let whereClause: any = {};

        if (role === 'client') {
            whereClause.client_id = userId;
        } else if (role === 'employee') {
            whereClause.assigned_employee_id = userId;
            // Note: Admins can see all, so no filter for them
        }

        const tickets = await prisma.ticket.findMany({
            where: whereClause,
            orderBy: [
                { status: 'asc' }, // usually we would sort by status importance, but let's keep it simple
                { sla_deadline: 'asc' }
            ],
            include: {
                category: true,
                assigned_employee: { select: { full_name: true, id: true } },
                images: true
            }
        });

        res.status(200).json({ status: 'success', tickets });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const getTicketById = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { role, userId } = req.user!;

        const ticket = await prisma.ticket.findUnique({
            where: { id },
            include: {
                category: true,
                client: { select: { full_name: true, email: true, id: true } },
                assigned_employee: { select: { full_name: true, id: true, email: true } },
                images: true,
                responses: {
                    include: {
                        employee: { select: { full_name: true } }
                    },
                    orderBy: { created_at: 'asc' }
                },
                audit_logs: {
                    orderBy: { changed_at: 'desc' }
                }
            }
        });

        if (!ticket) {
            res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ticket not found' } });
            return;
        }

        if (role === 'client' && ticket.client_id !== userId) {
            res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Not allowed to view this ticket' } });
            return;
        }
        if (role === 'employee' && ticket.assigned_employee_id !== userId) {
            res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Not allowed to view this ticket' } });
            return;
        }

        res.status(200).json({ status: 'success', ticket });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const uploadTicketImage = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { context } = req.body; // 'ticket' or 'response'

        if (!req.file) {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'No image file provided' } });
            return;
        }

        if (context !== 'ticket' && context !== 'response') {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Invalid context' } });
            return;
        }

        // Convert multer buffer to base64
        const base64Image = req.file.buffer.toString('base64');

        // Call ImgBB
        const formData = new URLSearchParams();
        formData.append('image', base64Image);
        const imgbbRes = await axios.post(`https://api.imgbb.com/1/upload?key=${process.env.IMGBB_API_KEY}`, formData.toString(), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });

        if (imgbbRes.data && imgbbRes.data.data) {
            const imgData = imgbbRes.data.data;

            const newImage = await prisma.ticketImage.create({
                data: {
                    ticket_id: id,
                    imgbb_url: imgData.url,
                    imgbb_delete_url: imgData.delete_url,
                    uploaded_by: req.user!.userId,
                    context: context,
                }
            });
            res.status(201).json({ status: 'success', image: newImage });
        } else {
            throw new Error('ImgBB upload failed');
        }
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const getTicketAudit = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;

        // Ensure ticket exists
        const ticket = await prisma.ticket.findUnique({ where: { id } });
        if (!ticket) {
            res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ticket not found' } });
            return;
        }

        const auditLogs = await prisma.ticketAuditLog.findMany({
            where: { ticket_id: id },
            orderBy: { changed_at: 'desc' },
        });

        res.status(200).json({ status: 'success', audit_logs: auditLogs });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};
