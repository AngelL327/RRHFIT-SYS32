Importar `exports/solicitudes_more.json` a Firestore
===============================================

Este script carga los documentos presentes en `exports/solicitudes_more.json` a la colección `solicitudes` en Firestore.

Requisitos
- Node.js (>=14)
- Un service account JSON con permisos para escribir en Firestore

Pasos (PowerShell)

1. Abrir PowerShell en la raíz del proyecto:

```powershell
cd 'C:\Users\andre\Documents\Projects\RRHFIT-SYS32'
```

2. Inicializar node (si no lo has hecho) e instalar dependencia:

```powershell
npm init -y
npm install firebase-admin
```

3. Exportar la variable de entorno con la ruta al service account JSON (ajusta la ruta):

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\path\to\serviceAccount.json'
```

4. Ejecutar el import:

```powershell
node .\scripts\import_solicitudes_to_firestore.js
```

Notas
- El script ahora usa IDs autogeneradas por Firestore para cada documento. No se usarán las claves del JSON como IDs.
- Se genera un archivo de mapeo `exports/solicitudes_id_map.json` con el par originalId -> newGeneratedId para referencia.
- Las cadenas ISO que contienen `T` se convierten a `Timestamp` de Firestore automáticamente.
- Los documentos se escriben con `merge: true` para no sobrescribir otros campos existentes.
- Si tienes más de 500 documentos el script hace commits en batches (400 por commit) para evitar límite.

Opcional: ajustar fechas localmente
---------------------------------
Si quieres distribuir las fechas del archivo `exports/solicitudes_more.json` entre los años 2021 y 2025 con meses variados, ejecuta el script de ajuste. El script hará un backup automático en `exports/solicitudes_more.bak.json` antes de modificar el archivo.

```powershell
node .\scripts\adjust_solicitudes_dates.js
```

Seguridad
- No subas tu service account JSON al repositorio. Manténlo en un directorio seguro y solo la ruta en la variable de entorno.
