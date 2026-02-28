import { PrismaClient, Ticket, User } from '@prisma/client';

const prisma = new PrismaClient();

export const assignTicket = async (ticketId: string): Promise<User | null> => {
    // 1. Get employees who are active, below max_capacity
    // 2. Sort by open counts (asc), then last_assigned (asc)

    const employees = await prisma.user.findMany({
        where: {
            role: 'employee',
            is_active: true,
            employee_profile: {
                open_ticket_count: {
                    lt: prisma.employeeProfile.fields.max_capacity,
                }
            }
        },
        include: {
            employee_profile: true
        },
        orderBy: [
            { employee_profile: { open_ticket_count: 'asc' } },
            { employee_profile: { last_assigned_at: 'asc' } }
        ],
        take: 1
    });

    if (employees.length === 0) {
        // Notify admin? In real scenario we'd trigger an event/notification.
        // For now, return null. The ticket remains OPEN.
        return null;
    }

    const selectedEmployee = employees[0];

    // Assign ticket and update counts, atomic transaction
    await prisma.$transaction([
        prisma.ticket.update({
            where: { id: ticketId },
            data: {
                status: 'assigned',
                assigned_employee_id: selectedEmployee.id,
            }
        }),
        prisma.employeeProfile.update({
            where: { user_id: selectedEmployee.id },
            data: {
                open_ticket_count: { increment: 1 },
                last_assigned_at: new Date(),
            }
        }),
        prisma.ticketAuditLog.create({
            data: {
                ticket_id: ticketId,
                from_status: 'open',
                to_status: 'assigned',
                actor_id: selectedEmployee.id, // System/Assignment Engine
                note: `Automatically assigned to ${selectedEmployee.email}`,
            }
        }),
        // Create an in-app notification for the employee
        prisma.notification.create({
            data: {
                user_id: selectedEmployee.id,
                type: 'TICKET_ASSIGNED',
                message: `You have been assigned a new ticket.`,
                payload_json: JSON.stringify({ ticketId }),
            }
        })
    ]);

    return selectedEmployee;
};
