const express = require('express');
const { Pool } = require('pg');
const { Kafka } = require('kafkajs');

const PORT = process.env.PORT || 3001;
const KAFKA_BROKERS = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
const KAFKA_TOPIC = process.env.KAFKA_TOPIC || 'orders';
const KAFKA_GROUP_ID = process.env.KAFKA_GROUP_ID || 'worker-group';

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'appdb',
});

const kafka = new Kafka({ clientId: 'worker-service', brokers: KAFKA_BROKERS });
const consumer = kafka.consumer({ groupId: KAFKA_GROUP_ID });

async function processMessage(orderId) {
  // Simulated processing delay, purely for demo visibility
  await new Promise((resolve) => setTimeout(resolve, 1000));
  await pool.query('UPDATE orders SET status = $1 WHERE id = $2', ['processed', orderId]);
  console.log(`Order ${orderId} marked as processed`);
}

async function start() {
  await consumer.connect();
  await consumer.subscribe({ topic: KAFKA_TOPIC, fromBeginning: false });

  await consumer.run({
    eachMessage: async ({ message }) => {
      const { orderId } = JSON.parse(message.value.toString());
      await processMessage(orderId);
    },
  });

  // Minimal health endpoint for K8s probes
  const app = express();
  app.get('/health', (req, res) => res.json({ status: 'ok' }));
  app.listen(PORT, () => console.log(`worker-service health endpoint on ${PORT}`));
}

start().catch((err) => {
  console.error('Failed to start worker-service:', err);
  process.exit(1);
});