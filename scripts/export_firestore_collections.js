/*
  Simple Node.js exporter for selected Firestore collections.
  Usage:
    1) Install node (>=14) and npm
    2) npm init -y
    3) npm install firebase-admin
    4) Download a Firebase service account JSON and set GOOGLE_APPLICATION_CREDENTIALS env var:
         $env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\path\to\serviceAccount.json'   # PowerShell
    5) node export_firestore_collections.js

  Output: files written to ./exports/<collection>.json
*/

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const COLLECTIONS = [
  'area',
  'departamento',
  'empleados',
  'nominas',
  'puesto',
  'solicitudes',
  'usuarios',
];

function ensureEnv() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error('\nERROR: environment variable GOOGLE_APPLICATION_CREDENTIALS not set.');
    console.error('Set it to the path of your Firebase service account JSON file.');
    process.exit(1);
  }
}

async function initFirebase() {
  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
    return admin.firestore();
  } catch (e) {
    console.error('Failed to initialize Firebase Admin SDK:', e);
    process.exit(1);
  }
}

async function exportCollection(db, name) {
  console.log(`Exporting collection: ${name}`);
  const out = {};
  try {
    const snapshot = await db.collection(name).get();
    snapshot.forEach(doc => {
      // convert Firestore Timestamp to ISO string if present
      const data = doc.data();
      const normalized = normalizeFirestoreTypes(data);
      out[doc.id] = normalized;
    });
    const outDir = path.join(process.cwd(), 'exports');
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
    const outPath = path.join(outDir, `${name}.json`);
    fs.writeFileSync(outPath, JSON.stringify(out, null, 2), 'utf8');
    console.log(`Wrote ${Object.keys(out).length} documents to ${outPath}\n`);
  } catch (e) {
    console.error(`Error exporting collection ${name}:`, e);
  }
}

function normalizeFirestoreTypes(obj) {
  if (obj === null || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map(normalizeFirestoreTypes);
  const res = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v && typeof v.toDate === 'function') {
      // likely a Firestore Timestamp
      try {
        res[k] = v.toDate().toISOString();
      } catch (_) {
        res[k] = String(v);
      }
    } else if (v && typeof v === 'object') {
      res[k] = normalizeFirestoreTypes(v);
    } else {
      res[k] = v;
    }
  }
  return res;
}

async function main() {
  ensureEnv();
  const db = await initFirebase();
  for (const c of COLLECTIONS) {
    await exportCollection(db, c);
  }
  console.log('Export complete. Files are in ./exports');
  process.exit(0);
}

main();
