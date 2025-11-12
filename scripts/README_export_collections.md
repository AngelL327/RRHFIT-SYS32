Export Firestore collections to JSON

This small helper exports a set of Firestore collections to JSON files under ./exports.
It uses the Firebase Admin SDK and requires a service account JSON.

Steps (Windows PowerShell)

1) Install Node.js (>=14) and npm if you don't have them.

2) Open a PowerShell in the project root and create a small package.json if needed:

```powershell
cd 'C:\Users\andre\Documents\Projects\RRHFIT-SYS32'
npm init -y
npm install firebase-admin
```

3) Download a Firebase service account JSON from your Firebase Console -> Project Settings -> Service accounts -> Generate new private key.
Save it somewhere safe, e.g. `C:\keys\firebase-service-account.json`.

4) Set the environment variable for the current PowerShell session (or configure it system-wide):

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\keys\firebase-service-account.json'
```

5) Run the exporter script:

```powershell
node scripts\export_firestore_collections.js
```

6) When finished you'll find files in `./exports/`:

- exports/area.json
- exports/departamento.json
- exports/empleados.json
- exports/nominas.json
- exports/puesto.json
- exports/solicitudes.json
- exports/usuarios.json

Notes

- The script normalizes Firestore Timestamp fields into ISO strings.
- If your collections have large numbers of documents or complex subcollections, consider using a more robust export (e.g. Firestore managed export to GCS) or iterate with pagination.
- The exporter does not include subcollections. If you need subcollections exported too, I can extend the script to recurse through doc.subcollections().

Security

Keep your service account JSON private. Do not commit it to the repository.

If you want, I can also:
- Add support to export subcollections recursively
- Export each collection as an array instead of an object keyed by doc id
- Compress the exports into a zip file
