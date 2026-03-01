import cron from 'node-cron';
import { PrismaClient } from '@prisma/client';
import { sendNotification } from '../services/notification.service';

const prisma = new PrismaClient();

export const initSlaMonitorJob = () => {
    // Run every 60 seconds
    cron.schedule('* * * * *', async () => {
        try {
            const now = new Date();

            // SLA WARNING
            // Tickets assigned/in_progress but approaching SLA
            // Default warning thresholds handled in config (not fully dynamic in query to keep simple)
            /* 
             To calculate warning, instead of dynamic query here, we can just check if sla_deadline 
             minus warning_hours is <= now. Let's do it simply by checking all tickets where
             sla_deadline > now and we haven't sent a warning yet.
            */

            const activeTickets = await prisma.ticket.findMany({
                where: {
                    status: { in: ['assigned', 'in_progress', 'revision_requested', 'reassigned'] },
                }
            });

            // Fetch configs nicely cached or directly from DB
            const configs = await prisma.slaConfig.findMany();
            const configMap = new Map(configs.map(c => [c.priority, c])); // map of priority -> { warning_hours, etc }

            for (const t of activeTickets) {
                if (!t.sla_deadline) continue;

                const config = configMap.get(t.priority) || { warning_hours: 2 }; // fallback 2 hrs

                // Check for breach
                if (t.sla_deadline <= now && t.status !== 'escalated') {
                    await prisma.ticket.update({
                        where: { id: t.id },
                        data: { status: 'escalated', escalated_at: now }
                    });

                    await prisma.ticketAuditLog.create({
                        data: { ticket_id: t.id, from_status: t.status, to_status: 'escalated', actor_id: t.assigned_employee_id || t.client_id, note: 'SLA Breached' }
                    });

                    if (t.assigned_employee_id) {
                        await sendNotification(t.assigned_employee_id, 'SLA Breached', `Ticket ${t.ticket_number} has breached its SLA.`);
                    }

                    // Notify admins
                    const admins = await prisma.user.findMany({ where: { role: 'admin' } });
                    for (const admin of admins) {
                        await sendNotification(admin.id, 'SLA Breached Flag', `Ticket ${t.ticket_number} escalated due to SLA breach.`);
                    }
                }

                // Check for warning
                else if (!t.sla_warning_sent_at && t.sla_deadline > now && t.status !== 'escalated') {
                    const warningTime = new Date(t.sla_deadline.getTime() - (config.warning_hours * 60 * 60 * 1000));
                    if (now >= warningTime) {
                        await prisma.ticket.update({
                            where: { id: t.id },
                            data: { sla_warning_sent_at: now }
                        });
                        if (t.assigned_employee_id) {
                            await sendNotification(t.assigned_employee_id, 'SLA Warning', `Hurry! Ticket ${t.ticket_number} is approaching SLA deadline.`);
                        }
                    }
                }
            }

        } catch (error) {
            console.error('SLA Monitor Job Error:', error);
        }
    });

    console.log('SLA Monitor cron job initialized.');
};
