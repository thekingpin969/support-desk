const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function seed() {
    console.log('Seeding database...');
    try {
        const passwordHash = await bcrypt.hash('admin123', 12);
        const admin = await prisma.user.upsert({
            where: { email_role: { email: 'admin@test.com', role: 'admin' } },
            update: {},
            create: {
                email: 'admin@test.com',
                password_hash: passwordHash,
                role: 'admin',
                full_name: 'Super Admin'
            }
        });

        const employeePasswordHash = await bcrypt.hash('employee123', 12);
        const employee = await prisma.user.upsert({
            where: { email_role: { email: 'employee@test.com', role: 'employee' } },
            update: {},
            create: {
                email: 'employee@test.com',
                password_hash: employeePasswordHash,
                role: 'employee',
                full_name: 'Test Employee',
                employee_profile: {
                    create: {
                        department: 'General Support',
                        max_capacity: 10
                    }
                }
            }
        });

        const clientPasswordHash = await bcrypt.hash('client123', 12);
        const client = await prisma.user.upsert({
            where: { email_role: { email: 'client@test.com', role: 'client' } },
            update: {},
            create: {
                email: 'client@test.com',
                password_hash: clientPasswordHash,
                role: 'client',
                full_name: 'Test Client'
            }
        });

        // Also seed some categories and SLA Configs
        const categories = ['Hardware', 'Software', 'Network', 'Account/Access'];
        for (const name of categories) {
            const existing = await prisma.category.findFirst({ where: { name } });
            if (!existing) {
                await prisma.category.create({ data: { name, is_active: true } });
            }
        }

        const priorities = [
            { priority: 'low', response_hours: 72, warning_hours: 12 },
            { priority: 'medium', response_hours: 24, warning_hours: 4 },
            { priority: 'high', response_hours: 8, warning_hours: 2 },
            { priority: 'critical', response_hours: 2, warning_hours: 1 }
        ];
        for (const p of priorities) {
            const existing = await prisma.slaConfig.findUnique({ where: { priority: p.priority } });
            if (!existing) {
                await prisma.slaConfig.create({ data: p });
            }
        }

        console.log('Seeded admin, categories, and SLAs.');
    } catch (error) {
        console.error('Error seeding database:', error);
    } finally {
        await prisma.$disconnect();
    }
}

seed();
