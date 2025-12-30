# Proyecto-ServerPC
## Servicios Transversales y Estructura de Logs

### 📌 Servicios definidos

1. **ErrorHandler**
   - Captura excepciones en cada capa.
   - Normaliza errores en un formato estándar (código + mensaje).
   - Llama al servicio de mensajes para obtener el texto asociado.
   - Envía el resultado al Logger.

2. **Logger**
   - Niveles: `INFO` (azul), `WARN` (amarillo), `ERROR` (rojo), `DEBUG` (gris/morado), `OK` (verde).
   - Salida múltiple:
     - Consola con colores.
     - Archivos en carpeta `logs/`.
     - Servicio externo (opcional).
   - Formato JSON para trazabilidad:
     ```json
     {
       "level": "ERROR",
       "code": "BFF_AUTH_001",
       "message": "Usuario no autorizado",
       "service": "BFF",
       "timestamp": "2025-12-30T19:33:00Z"
     }
     ```

3. **Sistema de Mensajes**
   - Centralizado en archivos JSON.
   - Organización por **capa** y por **servicio** dentro de cada capa.
   - Cada servicio empieza su numeración desde `001`.
   - Ejemplo:
     ```json
     {
       "FRONTEND": {
         "LOGIN": {
           "FRONT_LOGIN_001": "Credenciales inválidas, intente nuevamente.",
           "FRONT_LOGIN_002": "Usuario bloqueado por demasiados intentos fallidos."
         },
         "UPLOAD": {
           "FRONT_UPLOAD_001": "Error al subir archivo.",
           "FRONT_UPLOAD_002": "Formato de archivo no permitido."
         }
       },
       "BFF": {
         "AUTH": {
           "BFF_AUTH_001": "Usuario no autorizado.",
           "BFF_AUTH_002": "Token expirado."
         },
         "DB": {
           "BFF_DB_001": "Error de conexión a la base de datos.",
           "BFF_DB_002": "Consulta inválida."
         }
       },
       "BACKEND": {
         "GRPC": {
           "BACK_GRPC_001": "Timeout en comunicación gRPC.",
           "BACK_GRPC_002": "Servicio gRPC no disponible."
         },
         "STORAGE": {
           "BACK_STORAGE_001": "Archivo no encontrado en almacenamiento.",
           "BACK_STORAGE_002": "Error al escribir archivo en disco."
         }
       }
     }
     ```

---

### 📂 Estructura de carpetas de logs

```txt
Proyecto-ServerPC/
├── Backend/
├── BFF/
├── Frontend/
├── docs/
├── nginx-1.28.1/
└── logs/
    ├── backend/
    │   ├── auth/
    │   │   ├── backend_auth_2025-12-30.log
    │   │   └── backend_auth_2025-12-31.log
    │   ├── storage/
    │   │   ├── backend_storage_2025-12-30.log
    │   │   └── backend_storage_2025-12-31.log
    │   └── grpc/
    │       ├── backend_grpc_2025-12-30.log
    │       └── backend_grpc_2025-12-31.log
    ├── bff/
    │   ├── auth/
    │   │   ├── bff_auth_2025-12-30.log
    │   │   └── bff_auth_2025-12-31.log
    │   ├── db/
    │   │   ├── bff_db_2025-12-30.log
    │   │   └── bff_db_2025-12-31.log
    │   └── routes/
    │       ├── bff_routes_2025-12-30.log
    │       └── bff_routes_2025-12-31.log
    └── frontend/
        ├── login/
        │   ├── frontend_login_2025-12-30.log
        │   └── frontend_login_2025-12-31.log
        ├── upload/
        │   ├── frontend_upload_2025-12-30.log
        │   └── frontend_upload_2025-12-31.log
        └── ui/
            ├── frontend_ui_2025-12-30.log
            └── frontend_ui_2025-12-31.log

---

###🔹 Detalles clave

Carpeta por capa (backend/, bff/, frontend/).

Subcarpeta por servicio dentro de cada capa (auth/, storage/, login/, etc.).

Archivo por día → nombre incluye fecha (YYYY-MM-DD).

Rotación automática → cada día se genera un archivo nuevo.

Resiliencia → si falla el archivo, al menos se loguea en consola.

---

###📊 Flujo de integración

ErrorHandler captura excepción.

Busca código en el sistema de mensajes.

Devuelve mensaje asociado.

Logger registra en consola (con color), archivo y servicio externo.

El usuario recibe el mensaje de usuario si corresponde.