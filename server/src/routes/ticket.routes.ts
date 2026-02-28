import { Router } from 'express';
import multer from 'multer';
import { authenticate, requireRole } from '../middleware/auth.middleware';
import { createTicket, getTickets, getTicketById, uploadTicketImage } from '../controllers/ticket.controller';
import { createNewResponse, updateResponse, approveResponse, rejectResponse } from '../controllers/response.controller';
import { reassignTicket, escalateNotify, reopenTicket, rateTicket } from '../controllers/ticket-actions.controller';

const router = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } }); // 10MB

router.use(authenticate);

// Core CRUD
router.post('/', requireRole(['client']), createTicket);
router.get('/', getTickets);
router.get('/:id', getTicketById);

// Images
router.post('/:id/images', requireRole(['client', 'employee']), upload.single('image'), uploadTicketImage);

// Employee Responses
router.post('/:id/responses', requireRole(['employee']), createNewResponse);
router.post('/:id/responses/:rid/submit', requireRole(['employee']), updateResponse);

// Admin Actions
router.post('/:id/responses/:rid/approve', requireRole(['admin']), approveResponse);
router.post('/:id/responses/:rid/reject', requireRole(['admin']), rejectResponse);
router.post('/:id/reassign', requireRole(['admin']), reassignTicket);
router.post('/:id/escalate-notify', requireRole(['admin']), escalateNotify);

// Client Actions
router.post('/:id/reopen', requireRole(['client']), reopenTicket);
router.post('/:id/rate', requireRole(['client']), rateTicket);

// Audit
// router.get('/:id/audit', requireRole(['employee', 'admin']), getTicketAudit);

export default router;
