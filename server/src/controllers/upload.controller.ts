import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import axios from 'axios';

export const uploadImageObj = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.file) {
            res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'No image file provided' } });
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

            res.status(201).json({
                status: 'success',
                data: {
                    imgbb_url: imgData.url,
                    imgbb_delete_url: imgData.delete_url,
                }
            });
        } else {
            throw new Error('ImgBB upload failed');
        }
    } catch (err: any) {
        res.status(500).json({ error: { code: 'SERVER_ERROR', message: err.message } });
    }
};
