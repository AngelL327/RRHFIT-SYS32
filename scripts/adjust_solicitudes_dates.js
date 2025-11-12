const fs = require('fs');
const path = require('path');

const filePath = path.resolve(__dirname, '../exports/solicitudes_more.json');
const backupPath = path.resolve(__dirname, '../exports/solicitudes_more.bak.json');

if (!fs.existsSync(filePath)) {
  console.error('No se encontró', filePath);
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

// Backup original
fs.writeFileSync(backupPath, JSON.stringify(json, null, 2), 'utf8');
console.log('Backup escrito en', backupPath);

const keys = Object.keys(json);
keys.forEach((k, idx) => {
  const entry = json[k];
  // distribute years 2021..2025
  const year = 2021 + (idx % 5);
  const month = (idx % 12) + 1; // 1..12
  const day = ((idx * 3) % 28) + 1; // 1..28 safe

  const created = new Date(Date.UTC(year, month - 1, day, 9, 0, 0));
  const expediente = new Date(created);
  expediente.setUTCDate(created.getUTCDate() + 1);
  const inicio = new Date(created);
  inicio.setUTCDate(created.getUTCDate() + 2);
  const dur = 5 + (idx % 11); // 5..15 days
  const fin = new Date(inicio);
  fin.setUTCDate(inicio.getUTCDate() + dur);

  entry.creadoEn = created.toISOString();
  entry.fechaExpediente = expediente.toISOString();
  entry.fechaInicioIncapacidad = inicio.toISOString();
  entry.fechaFinIncapacidad = fin.toISOString();
});

fs.writeFileSync(filePath, JSON.stringify(json, null, 2), 'utf8');
console.log('Fechas actualizadas en', filePath);
console.log('Distribución aplicada: years 2021..2025, months varied.');
