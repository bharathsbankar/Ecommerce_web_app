const express = require('express');
const redis = require('redis');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5001;

app.use(express.json());

// Redis setup
const redisUrl = `redis://${process.env.REDIS_HOST || 'cart-db'}:${process.env.REDIS_PORT || 6379}`;
const redisClient = redis.createClient({ url: redisUrl });

redisClient.on('error', (err) => console.error('Redis Client Error', err));

(async () => {
    try {
        await redisClient.connect();
        console.log('Connected to Redis at:', redisUrl);
    } catch (err) {
        console.error('Failed to connect to Redis', err);
    }
})();

// Helper function to extract user_id from headers
const getUserId = (req) => {
    const userIdHeader = req.headers['x-user-id'];
    if (!userIdHeader) return null;
    return userIdHeader.toString();
};

// =========================================================================
// CUSTOMER CART ENDPOINTS (Via KrakenD Gateway)
// =========================================================================

// Get user's cart
app.get('/api/cart', async (req, res) => {
    const userId = getUserId(req);
    if (!userId) {
        return res.status(401).json({ error: 'Unauthorized: Missing user header' });
    }

    try {
        const cartKey = `cart:${userId}`;
        const cartData = await redisClient.hGetAll(cartKey);
        
        const items = [];
        for (const [productId, quantity] of Object.entries(cartData)) {
            items.push({
                productId: parseInt(productId, 10),
                quantity: parseInt(quantity, 10)
            });
        }
        
        return res.json({ userId, items });
    } catch (err) {
        console.error('Error fetching cart:', err);
        return res.status(500).json({ error: err.message });
    }
});

// Add or update cart item (handles soft-reservation TTL increment/decrement)
app.post('/api/cart', async (req, res) => {
    const userId = getUserId(req);
    if (!userId) {
        return res.status(401).json({ error: 'Unauthorized: Missing user header' });
    }

    const { productId, quantity } = req.body;
    if (productId === undefined || quantity === undefined) {
        return res.status(400).json({ error: 'productId and quantity are required' });
    }

    const qty = parseInt(quantity, 10);
    if (isNaN(qty) || qty < 0) {
        return res.status(400).json({ error: 'Quantity must be a non-negative integer' });
    }

    try {
        const cartKey = `cart:${userId}`;
        const resKey = `reservation:${productId}`;

        // Get current quantity in cart for this product
        const currentQtyStr = await redisClient.hGet(cartKey, productId.toString());
        const currentQty = currentQtyStr ? parseInt(currentQtyStr, 10) : 0;

        const diff = qty - currentQty;

        if (diff > 0) {
            // Increment soft-reservation count and set TTL of 5 minutes (300 seconds)
            await redisClient.incrBy(resKey, diff);
            await redisClient.expire(resKey, 300);
        } else if (diff < 0) {
            // Decrement soft-reservation count
            const newVal = await redisClient.incrBy(resKey, diff);
            if (newVal < 0) {
                await redisClient.set(resKey, '0');
            }
        }

        // Update cart structure
        if (qty > 0) {
            await redisClient.hSet(cartKey, productId.toString(), qty.toString());
        } else {
            await redisClient.hDel(cartKey, productId.toString());
        }

        return res.json({ message: 'Cart updated successfully', productId, quantity: qty });
    } catch (err) {
        console.error('Error updating cart:', err);
        return res.status(500).json({ error: err.message });
    }
});

// Remove item from cart completely
app.delete('/api/cart/:productId', async (req, res) => {
    const userId = getUserId(req);
    if (!userId) {
        return res.status(401).json({ error: 'Unauthorized: Missing user header' });
    }

    const { productId } = req.params;
    if (!productId) {
        return res.status(400).json({ error: 'productId is required' });
    }

    try {
        const cartKey = `cart:${userId}`;
        const resKey = `reservation:${productId}`;

        const currentQtyStr = await redisClient.hGet(cartKey, productId.toString());
        if (currentQtyStr) {
            const currentQty = parseInt(currentQtyStr, 10);
            const newVal = await redisClient.incrBy(resKey, -currentQty);
            if (newVal < 0) {
                await redisClient.set(resKey, '0');
            }
            await redisClient.hDel(cartKey, productId.toString());
        }

        return res.json({ message: 'Product removed from cart' });
    } catch (err) {
        console.error('Error removing item from cart:', err);
        return res.status(500).json({ error: err.message });
    }
});

// Clear cart
app.delete('/api/cart', async (req, res) => {
    const userId = getUserId(req);
    if (!userId) {
        return res.status(401).json({ error: 'Unauthorized: Missing user header' });
    }

    try {
        const cartKey = `cart:${userId}`;
        const cartData = await redisClient.hGetAll(cartKey);

        for (const [productId, quantity] of Object.entries(cartData)) {
            const qty = parseInt(quantity, 10);
            const resKey = `reservation:${productId}`;
            const newVal = await redisClient.incrBy(resKey, -qty);
            if (newVal < 0) {
                await redisClient.set(resKey, '0');
            }
        }

        await redisClient.del(cartKey);
        return res.json({ message: 'Cart cleared successfully' });
    } catch (err) {
        console.error('Error clearing cart:', err);
        return res.status(500).json({ error: err.message });
    }
});

// =========================================================================
// INTERNAL / DECOUPLED ENDPOINTS (Service-to-Service)
// =========================================================================

// Retrieve active reservation count for a specific product
app.get('/api/cart/reservations/:productId', async (req, res) => {
    const { productId } = req.params;
    try {
        const resKey = `reservation:${productId}`;
        const value = await redisClient.get(resKey);
        const count = value ? parseInt(value, 10) : 0;
        // Return plain text number so Spring RestTemplate parses it directly as Integer
        res.setHeader('Content-Type', 'text/plain');
        return res.send(count.toString());
    } catch (err) {
        console.error('Error fetching reservations:', err);
        return res.status(500).send('0');
    }
});

// Get user's cart internally (called by Order Service during checkout)
app.get('/api/cart/internal/:userId', async (req, res) => {
    const { userId } = req.params;
    try {
        const cartKey = `cart:${userId}`;
        const cartData = await redisClient.hGetAll(cartKey);
        
        const items = [];
        for (const [productId, quantity] of Object.entries(cartData)) {
            items.push({
                productId: parseInt(productId, 10),
                quantity: parseInt(quantity, 10)
            });
        }
        
        return res.json(items);
    } catch (err) {
        console.error('Error fetching internal cart:', err);
        return res.status(500).json({ error: err.message });
    }
});

// Clear user's cart internally (called by Order Service after successful checkout)
app.post('/api/cart/internal/:userId/clear', async (req, res) => {
    const { userId } = req.params;
    try {
        const cartKey = `cart:${userId}`;
        const cartData = await redisClient.hGetAll(cartKey);

        for (const [productId, quantity] of Object.entries(cartData)) {
            const qty = parseInt(quantity, 10);
            const resKey = `reservation:${productId}`;
            const newVal = await redisClient.incrBy(resKey, -qty);
            if (newVal < 0) {
                await redisClient.set(resKey, '0');
            }
        }

        await redisClient.del(cartKey);
        return res.json({ message: 'Internal cart cleared successfully' });
    } catch (err) {
        console.error('Error clearing internal cart:', err);
        return res.status(500).json({ error: err.message });
    }
});

app.listen(PORT, () => {
    console.log(`Cart Service listening on port ${PORT}`);
});
