# Proyecto-ServerPC
## Servidor Personal de Transferencia de Archivos

### 📌 Objetivo del Proyecto
Este proyecto busca crear un **servidor personal de transferencia de archivos**, pensado para uso **individual o familiar**, sin depender de servicios comerciales ni infraestructura paga.

El sistema permite:
- Subir archivos desde web o móvil
- Descargar archivos desde otra sesión/dispositivo
- Controlar **quién puede acceder a cada archivo**
- Mantener los archivos **fuera del dominio del proyecto** una vez descargados
- Priorizar **seguridad, control y simplicidad**

> ⚠️ No es un sistema de almacenamiento en la nube, sino un **puente de transferencia controlado**.

---

### 🏗️ Arquitectura General
[ Frontend (Next.js) ]
↓
[ BFF - Python (Auth, Seguridad) ]
↓
[ Backend - Go (Transferencias) ]
↓
[ Disco local (carpeta temporal) ]

---

### 📂 Estructura de Carpetas
```txt
Backend/
├── cmd/server/           # main.go (punto de entrada del servidor Go)
├── pkg/
│   ├── auth/             # autenticación y autorización
│   ├── grpc/             # implementación de servicios gRPC
│   ├── storage/          # lógica de almacenamiento de archivos
│   └── utils/            # funciones auxiliares y helpers
├── proto/                # contratos gRPC (.proto)
└── tests/
    ├── e2e/              # pruebas end-to-end con BFF
    ├── integration/      # pruebas de integración de servicios gRPC
    └── unit/             # pruebas unitarias

BFF/
├── app/
│   ├── grpc_clients/     # clientes gRPC para hablar con Backend
│   ├── models/           # modelos de datos (Pydantic)
│   ├── routes/           # endpoints REST (ej: auth.py, upload.py)
│   ├── services/         # lógica de negocio (validaciones, seguridad)
│   └── utils/            # middlewares y helpers
├── database/
│   ├── database.db       # archivo SQLite
│   ├── schemas.sql       # definición de tablas
│   ├── init_db.py        # script de inicialización/verificación
│   └── backups/          # copias de seguridad
├── tests/
│   ├── e2e/              # pruebas completas con Backend simulado
│   ├── integration/      # pruebas de endpoints REST
│   └── unit/             # pruebas unitarias
│       └── Scripts/      # scripts auxiliares para testing

Frontend/
└── src/
    ├── app/              # rutas App Router (Next.js 13+)
    ├── components/       # componentes reutilizables
    ├── styles/           # estilos globales y específicos
    └── tests/
        ├── e2e/          # pruebas end-to-end (ej. Playwright/Cypress)
        ├── integration/  # pruebas de integración
        └── unit/         # pruebas unitarias

nginx-1.28.1/             # servidor Nginx descargado (binarios y conf)

docs/
├── frontend/              # documentación específica del Frontend
│   ├── arquitectura.md    # estructura de carpetas y componentes
│   ├── estilos.md         # convenciones de CSS/estilos
│   ├── tests.md           # cómo correr unit/integration/e2e
│   └── guia_uso.md        # cómo levantar y usar el Frontend

├── bff/                   # documentación específica del BFF (Python/FastAPI)
│   ├── arquitectura.md    # estructura de app/, routes/, services/
│   ├── database.md        # tablas SQL, init_db.py, backups
│   ├── endpoints.md       # API REST expuesta
│   ├── seguridad.md       # login, TOTP, roles, permisos
│   └── tests.md           # pruebas unitarias, integración y e2e

├── backend/               # documentación específica del Backend (Go/gRPC)
│   ├── arquitectura.md    # estructura de cmd/, pkg/, proto/
│   ├── servicios.md       # servicios gRPC implementados
│   ├── storage.md         # lógica de almacenamiento
│   ├── tests.md           # pruebas unitarias, integración y e2e
│   └── roadmap.md         # mejoras futuras

└── general/               # documentación transversal
    ├── estructura.md      # árbol completo del proyecto
    ├── seguridad.md       # principios generales de seguridad
    ├── flujo.md           # flujo de subida/descarga de archivos
    └── instalacion.md     # guía rápida para levantar todo el sistema

└── otros/               # documentación complementaria

## 📖 Documentación

- [Frontend](docs/frontend/arquitectura.md)
- [BFF](docs/bff/arquitectura.md)
- [Backend](docs/backend/arquitectura.md)
- [General](docs/general/estructura.md)
- [Otros](docs/otros/)

### 🔐 Filosofía de Seguridad
- Nada público por defecto  
- Ningún archivo accesible sin autenticación  
- Permisos **explícitos por archivo**  
- Los paths reales nunca se exponen  
- El servidor no decide dónde se guarda el archivo final  

---

### 🗄️ Base de Datos (SQLite)
La base de datos **no almacena archivos**, solo **estado, seguridad y control**.

Tablas principales:
- `users` → usuarios, roles y estado  
- `user_totp` → secretos TOTP y verificación  
- `transfers` → transferencias temporales (UUID, estado, propietario)  
- `upload_sessions` → subidas reanudables por chunks  
- `transfer_permissions` → permisos explícitos por archivo  

📖 La definición completa de tablas está en [`docs/database.md`](docs/database.md).

---

### 🔑 Sistema de Autenticación
- **Login**: usuario + password (bcrypt/argon2)  
- **Segundo factor (TOTP)**: compatible con Google Authenticator/Authy  
- **Tokens**:  
  - Access Token (JWT) → corto (5–10 min)  
  - Refresh Token → almacenado hasheado en DB  

---

### 🛂 Control de Acceso
- Roles: `admin`, `user`  
- Permisos por archivo: `read`, `manage`  
- Regla: *nadie puede descargar un archivo sin un permiso explícito*  

---

### 🌐 Endpoints Principales
#### Autenticación

POST   /auth/login
POST   /auth/totp/verify
POST   /auth/refresh
POST   /auth/logout


#### Transferencias
POST   /transfers                # crear transferencia
POST   /transfers/{id}/upload    # subir chunks
GET    /transfers                # listar transferencias disponibles
GET    /transfers/{id}/download  # descargar archivo
POST   /transfers/{id}/share     # compartir con otro usuario
POST   /transfers/{id}/consume   # marcar como consumido


---

### 📲 Flujo de Uso
#### Subida desde móvil
1. Login + TOTP  
2. Crear transferencia  
3. Subida por chunks  
4. Estado = `uploaded`  

#### Descarga en PC
1. Login  
2. Listar transferencias permitidas  
3. Descargar  
4. Guardar fuera del proyecto  
5. Marcar como `consumed`  

---

### 🗂️ Gestión de Archivos
- Archivos viven en carpeta temporal del proyecto  
- El proyecto **no controla** la ubicación final  
- Limpieza y archivado mediante scripts externos  

---

### 🚀 Escalabilidad y Futuro
- Docker  
- Más roles  
- Enlaces temporales  
- Clientes mobile dedicados  

---

### 📖 Principios Clave
- Seguridad primero  
- Control explícito  
- Simplicidad  
- Sin dependencia de terceros  
- Proyecto personal, extensible y mantenible  

---

✍️ **Este README define la base conceptual y técnica del proyecto y sirve como guía para futuras iteraciones o colaboración.**
