const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('ERROR: Debes exportar la variable de entorno GOOGLE_APPLICATION_CREDENTIALS con la ruta al service account JSON.');
  console.error('En PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\path\\to\\serviceAccount.json"');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

//const filePath = path.resolve(__dirname, '../exports/solicitudes_more.json');
const filePath = path.resolve(__dirname, '../exports/solicitudes_test.json');

if (!fs.existsSync(filePath)) {
  console.error('No se encontró el archivo:', filePath);
  process.exit(1);
}

const raw = fs.readFileSync(filePath, 'utf8');
let json;
try {
  json = JSON.parse(raw);
} catch (err) {
  console.error('Error parseando JSON:', err.message);
  process.exit(1);
}

const COLLECTION = 'incapacidades';
// Si prefieres otra colección, cámbiala o adapta para recibir por argumento

function convertValue(val) {
  if (typeof val === 'string') {
    // detectar ISO datetimes simples que contienen 'T' y convertir a Timestamp
    if (val.includes('T')) {
      const d = new Date(val);
      if (!isNaN(d.getTime())) return admin.firestore.Timestamp.fromDate(d);
    }
    return val;
  }
  if (Array.isArray(val)) return val.map(convertValue);
  if (val && typeof val === 'object') {
    const out = {};
    for (const k of Object.keys(val)) out[k] = convertValue(val[k]);
    return out;
  }
  return val;
}

async function run() {
  const entries = Object.entries(json);
  console.log(`Importando ${entries.length} documentos a la colección '${COLLECTION}' (archivo: ${filePath})`);

  let batch = db.batch();
  let processed = 0;
  const idMap = {};
  for (const [docId, doc] of entries) {
    // usar ID autogenerado por Firestore
    const docRef = db.collection(COLLECTION).doc();
    idMap[docId] = docRef.id;
    const converted = {};
    for (const [k, v] of Object.entries(doc)) converted[k] = convertValue(v);
    batch.set(docRef, converted, { merge: true });
    processed++;

    // commit cada 400 docs para mantenerse seguro (limite 500)
    if (processed % 400 === 0) {
      await batch.commit();
      console.log(`  - Committed ${processed} documentos...`);
      batch = db.batch();
    }
  }

  // commit restante
  try {
    await batch.commit();
    console.log(`  - Committed final batch. Total importados: ${processed}`);
  } catch (err) {
    console.error('Error al commitear batch final:', err);
  }
  // Escribir archivo con mapeo original -> nuevo ID para referencia
  try {
    const mapPath = path.resolve(__dirname, '../exports/solicitudes_id_map.json');
    fs.writeFileSync(mapPath, JSON.stringify(idMap, null, 2), 'utf8');
    console.log('Wrote ID map to', mapPath);
  } catch (err) {
    console.error('No se pudo escribir el archivo de mapeo de IDs:', err);
  }

  console.log('Import completed. Revisa la colección', COLLECTION, 'en Firestore.');
}

run().catch(err => {
  console.error('Error durante la importación:', err);
  process.exit(1);
});
