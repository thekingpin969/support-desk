const axios = require('axios');

const API_URL = 'http://localhost:3000/v1';

async function runE2ETests() {
    console.log('Starting E2E API Verification...');

    try {
        const clientEmail = `client_${Date.now()}@test.com`;
        const clientPass = 'password123';
        console.log(`Registering client: ${clientEmail}`);

        await axios.post(`${API_URL}/auth/register`, {
            email: clientEmail,
            password: clientPass,
            full_name: 'Test Client',
            phone: '1234567890'
        });

        console.log('Client registration successful.');

        const loginRes = await axios.post(`${API_URL}/auth/login`, {
            email: clientEmail,
            password: clientPass
        });
        const clientToken = loginRes.data.access_token;
        console.log('Client login successful.');

    } catch (err) {
        if (err.response) {
            console.error('API Error:', err.response.data);
        } else {
            console.error('Network Error:', err.message);
        }
    }
}

runE2ETests();
