const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const { Kafka } = require('kafkajs');

const PORT = process.env.PORT || 3000;
const KAFKA_BROKERS = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
const KAFKA_TOPIC = process.env.KAFKA_TOPIC || 'orders';

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'appdb',
});

const kafka = new Kafka({ clientId: 'order-service', brokers: KAFKA_BROKERS });
const producer = kafka.producer();

async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS orders (
      id SERIAL PRIMARY KEY,
      item TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  `);
}

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.get('/orders', async (req, res) => {
  const result = await pool.query('SELECT * FROM orders ORDER BY id DESC LIMIT 50');
  res.json(result.rows);
});

app.post('/orders', async (req, res) => {
  const { item, quantity } = req.body;
  if (!item || !quantity) {
    return res.status(400).json({ error: 'item and quantity are required' });
  }
  const result = await pool.query(
    'INSERT INTO orders (item, quantity, status) VALUES ($1, $2, $3) RETURNING *',
    [item, quantity, 'pending']
  );
  const order = result.rows[0];

  await producer.send({
    topic: KAFKA_TOPIC,
    messages: [{ value: JSON.stringify({ orderId: order.id }) }],
  });

  res.status(201).json(order);
});

async function start() {
  await initDb();
  await producer.connect();
  app.listen(PORT, () => console.log(`order-service listening on ${PORT}`));
}

start().catch((err) => {
  console.error('Failed to start order-service:', err);
  process.exit(1);
});