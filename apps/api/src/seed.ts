import { MongoClient } from 'mongodb';
import { loadConfig } from './config';
import { demoProperties } from './fixtures';
async function main() {
  const config = loadConfig();
  if (!config.demo || config.environment === 'production') throw new Error('Seeding requires non-production demo mode');
  const client = new MongoClient(config.mongoUri);
  try {
    await client.connect();
    const db = client.db();
    await db.command({ [await db.listCollections({ name: 'properties' }).hasNext() ? 'collMod' : 'create']: 'properties', validator: { $jsonSchema: { bsonType: 'object', required: ['id', 'synthetic', 'status', 'currency', 'illustrativeValueMinor'], properties: { id: { bsonType: 'string' }, synthetic: { enum: [true] }, status: { enum: ['demo_only'] }, currency: { enum: ['USD'] }, illustrativeValueMinor: { bsonType: ['int', 'long', 'double'], minimum: 0, multipleOf: 1 } } } }, validationLevel: 'strict', validationAction: 'error' });
    const collection = db.collection('properties');
    await collection.createIndex({ id: 1 }, { unique: true });
    for (const property of demoProperties) await collection.updateOne({ id: property.id }, { $set: property }, { upsert: true });
    console.log(`Upserted ${demoProperties.length} synthetic properties`);
  } finally { await client.close(); }
}
void main().catch(() => { console.error('Seed failed; check development configuration and database connectivity'); process.exitCode = 1; });
