import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import morgan from 'morgan';
import helmet from 'helmet';

// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
    origin: process.env.CORS_ORIGINS ? process.env.CORS_ORIGINS.split(',') : '*',
}));
app.use(express.json());
app.use(morgan('dev'));

// Basic health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

import authRoutes from './routes/auth.routes';
import ticketRoutes from './routes/ticket.routes';
import adminRoutes from './routes/admin.routes';
import employeeRoutes from './routes/employee.routes';
import notificationRoutes from './routes/notification.routes';
import { initSlaMonitorJob } from './jobs/sla-monitor.job';

// Init background jobs
initSlaMonitorJob();

// Import Routes (To be created)
app.use('/v1/auth', authRoutes);
app.use('/v1/tickets', ticketRoutes);
app.use('/v1/admin', adminRoutes);
app.use('/v1/employees', employeeRoutes);
app.use('/v1/notifications', notificationRoutes);

// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
    console.error(err.stack);
    res.status(err.status || 500).json({
        error: {
            code: err.code || 'INTERNAL_SERVER_ERROR',
            message: err.message || 'An unexpected error occurred',
        },
    });
});

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
