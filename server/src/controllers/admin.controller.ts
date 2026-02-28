import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/auth.middleware';
import { z } from 'zod';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const employeeSchema = z.object({
    email: z.string().email(),
    password: z.string().min(6),
    full_name: z.string().min(1),
    department: z.string().optional(),
    max_capacity: z.number().int().min(1).optional(),
});

export const getEmployees = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const employees = await prisma.user.findMany({
            where: { role: 'employee' },
            include: {
                employee_profile: true,
            },
        });

        res.status(200).json({ status: 'success', employees });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const createEmployee = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const data = employeeSchema.parse(req.body);
        const existing = await prisma.user.findUnique({ where: { email: data.email } });
        if (existing) {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Email already exists' } });
            return;
        }

        const hash = await bcrypt.hash(data.password, 12);

        const user = await prisma.user.create({
            data: {
                email: data.email,
                password_hash: hash,
                full_name: data.full_name,
                role: 'employee',
                employee_profile: {
                    create: {
                        department: data.department,
                        max_capacity: data.max_capacity ?? 10,
                    }
                }
            },
            include: { employee_profile: true }
        });

        res.status(201).json({ status: 'success', employee: { id: user.id, email: user.email, profile: user.employee_profile } });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const updateEmployee = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { department, max_capacity, is_active } = req.body;

        await prisma.$transaction(async (tx) => {
            if (is_active !== undefined) {
                await tx.user.update({
                    where: { id },
                    data: { is_active }
                });

                if (is_active === false) {
                    // Relieve assignments
                    const openTickets = await tx.ticket.findMany({
                        where: { assigned_employee_id: id, status: { in: ['assigned', 'in_progress', 'revision_requested'] } }
                    });

                    await tx.ticket.updateMany({
                        where: { assigned_employee_id: id, status: { in: ['assigned', 'in_progress', 'revision_requested'] } },
                        data: { assigned_employee_id: null, status: 'open' }
                    });

                    await tx.employeeProfile.update({
                        where: { user_id: id },
                        data: { open_ticket_count: 0 }
                    });
                }
            }

            if (department !== undefined || max_capacity !== undefined) {
                await tx.employeeProfile.update({
                    where: { user_id: id },
                    data: {
                        department: department !== undefined ? department : undefined,
                        max_capacity: max_capacity !== undefined ? max_capacity : undefined,
                    }
                });
            }
        });

        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const getEmployeeTickets = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const tickets = await prisma.ticket.findMany({
            where: { assigned_employee_id: id },
            orderBy: { created_at: 'desc' }
        });
        res.status(200).json({ status: 'success', tickets });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const getAnalytics = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const [totalToday, pendingReview, escalated] = await Promise.all([
            prisma.ticket.count({ where: { created_at: { gte: today } } }),
            prisma.ticket.count({ where: { status: 'pending_review' } }),
            prisma.ticket.count({ where: { status: 'escalated' } })
        ]);

        res.status(200).json({
            status: 'success',
            data: {
                total_today: totalToday,
                pending_review: pendingReview,
                escalated: escalated,
            }
        });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const getSlaConfig = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const configs = await prisma.slaConfig.findMany();
        res.status(200).json({ status: 'success', configs });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const updateSlaConfig = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { configs } = req.body; // array of { priority, response_hours, warning_hours }

        await prisma.$transaction(
            configs.map((c: any) =>
                prisma.slaConfig.upsert({
                    where: { priority: c.priority },
                    update: { response_hours: c.response_hours, warning_hours: c.warning_hours },
                    create: { priority: c.priority, response_hours: c.response_hours, warning_hours: c.warning_hours }
                })
            )
        );

        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const getCategories = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const categories = await prisma.category.findMany();
        res.status(200).json({ status: 'success', categories });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const createCategory = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { name } = req.body;
        const category = await prisma.category.create({ data: { name } });
        res.status(201).json({ status: 'success', category });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};

export const editCategory = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { name, is_active } = req.body;
        await prisma.category.update({
            where: { id },
            data: { name, is_active }
        });
        res.status(200).json({ status: 'success' });
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};
