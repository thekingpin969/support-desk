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
    // origin: process.env.CORS_ORIGINS ? process.env.CORS_ORIGINS.split(',') : '*',
    origin: '*',
}));
app.use(express.json());
app.use(morgan('dev'));

// Detailed Request/Response Logging Middleware
app.use((req, res, next) => {
    console.log(`\n[${new Date().toISOString()}] Incoming Request: ${req.method} ${req.originalUrl}`);
    if (req.body && Object.keys(req.body).length > 0) {
        console.log('Request Body:', JSON.stringify(req.body, null, 2));
    }

    const originalSend = res.send;
    let responseSent = false;

    res.send = function (body) {
        if (!responseSent) {
            console.log(`[${new Date().toISOString()}] Outgoing Response: ${req.method} ${req.originalUrl} - Status: ${res.statusCode}`);
            try {
                const parsed = typeof body === 'string' ? JSON.parse(body) : body;
                console.log('Response Body:', JSON.stringify(parsed, null, 2));
            } catch (e) {
                console.log('Response Body:', body);
            }
            responseSent = true;
        }
        return originalSend.call(this, body);
    };

    next();
});

// Basic health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

import authRoutes from './routes/auth.routes';
import ticketRoutes from './routes/ticket.routes';
import adminRoutes from './routes/admin.routes';
import employeeRoutes from './routes/employee.routes';
import notificationRoutes from './routes/notification.routes';
import uploadRoutes from './routes/upload.routes';
import { initSlaMonitorJob } from './jobs/sla-monitor.job';

// Init background jobs
initSlaMonitorJob();

// Routes
app.use('/v1/auth', authRoutes);

// Import Routes (To be created)
app.use('/v1/tickets', ticketRoutes);
app.use('/v1/admin', adminRoutes);
app.use('/v1/employees', employeeRoutes);
app.use('/v1/notifications', notificationRoutes);
app.use('/v1/upload', uploadRoutes);

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
