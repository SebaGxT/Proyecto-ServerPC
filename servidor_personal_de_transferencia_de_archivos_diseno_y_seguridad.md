# Servidor Personal de Transferencia de Archivos

## 1. Objetivo del Proyecto

Este proyecto tiene como finalidad crear un **servidor personal de transferencia de archivos**, pensado para uso **individual o familiar**, sin depender de servicios comerciales ni infraestructura paga.

El sistema permite:
- Subir archivos desde web o móvil
- Descargar archivos desde otra sesión/dispositivo
- Controlar **quién puede acceder a cada archivo**
- Mantener los archivos **fuera del dominio del proyecto** una vez descargados
- Priorizar **seguridad, control y simplicidad**

No es un sistema de almacenamiento en la nube, sino un **puente de transferencia controlado**.

---

## 2. Arquitectura General

```
[ Frontend (Next.js) ]
        ↓
[ BFF - Python (Auth, Seguridad) ]
        ↓
[ Backend - Go (Transferencias) ]
        ↓
[ Disco local (carpeta temporal) ]
```

### Componentes

- **Frontend (Next.js)**
  - UI web responsive (desktop / mobile)
  - Login + TOTP
  - Subida y descarga de archivos

- **BFF (Python)**
  - Autenticación
  - Validación de TOTP
  - Autorización (roles + permisos)
  - Rate limit

- **Backend (Go)**
  - Subida por chunks
  - Gestión de transferencias
  - Streaming de descargas

---

## 3. Filosofía de Seguridad

- Nada público por defecto
- Ningún archivo es accesible sin autenticación
- Permisos **explícitos por archivo**
- Los paths reales nunca se exponen
- El servidor no decide dónde se guarda el archivo final

---

## 4. Base de Datos (SQLite)

La base de datos **no almacena archivos**, solo **estado, seguridad y control**.

### 4.1 Tabla `users`

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT CHECK(role IN ('admin','user')) NOT NULL,
  is_active BOOLEAN DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  last_login_at DATETIME
);
```

---

### 4.2 Tabla `user_totp`

```sql
CREATE TABLE user_totp (
  user_id INTEGER PRIMARY KEY,
  totp_secret TEXT NOT NULL,
  enabled BOOLEAN DEFAULT 0,
  verified_at DATETIME,
  FOREIGN KEY(user_id) REFERENCES users(id)
);
```

---

### 4.3 Tabla `transfers`

Representa una transferencia temporal, no almacenamiento.

```sql
CREATE TABLE transfers (
  id TEXT PRIMARY KEY, -- UUID
  owner_user_id INTEGER NOT NULL,
  original_name TEXT NOT NULL,
  mime_type TEXT,
  size INTEGER,
  checksum TEXT,
  status TEXT CHECK(status IN (
    'pending_upload',
    'uploading',
    'uploaded',
    'consumed',
    'archived'
  )) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  uploaded_at DATETIME,
  consumed_at DATETIME,
  FOREIGN KEY(owner_user_id) REFERENCES users(id)
);
```

---

### 4.4 Tabla `upload_sessions`

Permite subidas reanudables.

```sql
CREATE TABLE upload_sessions (
  id TEXT PRIMARY KEY,
  transfer_id TEXT NOT NULL,
  chunk_size INTEGER NOT NULL,
  total_chunks INTEGER NOT NULL,
  uploaded_chunks INTEGER DEFAULT 0,
  status TEXT CHECK(status IN ('active','completed','failed')),
  last_activity_at DATETIME,
  FOREIGN KEY(transfer_id) REFERENCES transfers(id)
);
```

---

### 4.5 Tabla `transfer_permissions`

Control de acceso por archivo.

```sql
CREATE TABLE transfer_permissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transfer_id TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  permission TEXT CHECK(permission IN ('read','manage')) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(transfer_id) REFERENCES transfers(id),
  FOREIGN KEY(user_id) REFERENCES users(id)
);
```

---

## 5. Sistema de Autenticación + TOTP

### 5.1 Login

- Usuario + password
- Passwords hasheados (bcrypt / argon2)

### 5.2 Segundo Factor (TOTP)

- Compatible con Google Authenticator / Authy
- Flujo:
  1. Generar secreto
  2. Mostrar QR
  3. Verificar código
  4. Activar TOTP

### 5.3 Tokens

- **Access Token (JWT)** → corto (5–10 min)
- **Refresh Token** → almacenado hasheado en DB

---

## 6. Control de Acceso

- Roles (`admin`, `user`) → gestión del sistema
- Permisos por archivo → acceso real a datos

Regla:
> Nadie puede descargar un archivo sin un permiso explícito.

---

## 7. Endpoints Principales

### Autenticación

```
POST   /auth/login
POST   /auth/totp/verify
POST   /auth/refresh
POST   /auth/logout
```

---

### Transferencias

```
POST   /transfers                # crear transferencia
POST   /transfers/{id}/upload    # subir chunks
GET    /transfers                # listar disponibles para el usuario
GET    /transfers/{id}/download  # descargar archivo
POST   /transfers/{id}/share     # compartir con otro usuario
POST   /transfers/{id}/consume   # marcar como consumido
```

---

## 8. Flujo Completo de Uso

### Subida desde móvil
1. Login + TOTP
2. Crear transferencia
3. Subida por chunks
4. Estado = `uploaded`

### Descarga en PC
1. Login
2. Listar transferencias permitidas
3. Descargar
4. Guardar fuera del proyecto
5. Marcar como `consumed`

---

## 9. Gestión de Archivos

- Archivos viven en una carpeta temporal del proyecto
- El proyecto **no controla** la ubicación final
- Limpieza y archivado pueden hacerse con scripts externos

---

## 10. Escalabilidad y Futuro

- Docker
- Linux
- PostgreSQL
- Más roles
- Enlaces temporales
- Clientes mobile dedicados

---

## 11. Principios Clave

- Seguridad primero
- Control explícito
- Simplicidad
- Sin dependencia de terceros
- Proyecto personal, extensible y mantenible

---

**Este documento define la base conceptual y técnica del proyecto y sirve como guía para futuras iteraciones o colaboración con otras IA.**

