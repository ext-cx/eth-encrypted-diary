import { ethers } from 'ethers';

export default async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', 'https://ext-cx.github.io');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Signature, X-Message');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    const signature = req.headers['x-signature'];
    const message = req.headers['x-message'];

    if (!signature || !message) {
        return res.status(401).json({ error: 'Signature required' });
    }

    const timestamp = parseInt(message);
    if (Math.abs(Date.now() - timestamp) > 60000) {
        return res.status(401).json({ error: 'Signature expired' });
    }

    try {
        const recovered = ethers.verifyMessage(message, signature);
        if (recovered.toLowerCase() !== process.env.OWNER_ADDRESS.toLowerCase()) {
            return res.status(403).json({ error: 'Not authorized' });
        }
    } catch (err) {
        return res.status(401).json({ error: 'Invalid signature' });
    }

    try {
        const response = await fetch('https://api.pinata.cloud/users/generateApiKey', {
            method: 'POST',
            headers: {
                'Authorization': 'Bearer ' + process.env.PINATA_JWT,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                keyName: 'upload-' + Date.now(),
                maxUses: 3,
                permissions: {
                    endpoints: {
                        pinning: {
                            pinFileToIPFS: true
                        }
                    }
                }
            }),
        });

        const data = await response.json();
        return res.status(response.status).json({ jwt: data.JWT });
    } catch (err) {
        return res.status(500).json({ error: err.message });
    }
}