import * as admin from 'firebase-admin';
import { PrismaClient } from '@prisma/client';
import path from 'path';

const prisma = new PrismaClient();

try {
    const serviceAccountPath = path.resolve(process.cwd(), 'firebase-admin.json');
    admin.initializeApp({
        credential: admin.credential.cert(require(serviceAccountPath)),
    });
    console.log('Firebase Admin initialized successfully');
} catch (error) {
    console.error('Firebase Admin initialization failed. Proceeding without FCM.', error);
}

export const sendNotification = async (userId: string, title: string, body: string, data?: any) => {
    try {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (!user) return;

        // Save in-app notification
        await prisma.notification.create({
            data: {
                user_id: userId,
                type: 'GENERAL',
                message: body,
                payload_json: data ? JSON.stringify(data) : null,
            }
        });

        // Send push notification if FCM token exists
        if (user.fcm_token) {
            await admin.messaging().send({
                token: user.fcm_token,
                notification: {
                    title,
                    body,
                },
                data: data || {},
            });
        }
    } catch (error) {
        console.error('Failed to send notification:', error);
    }
};
