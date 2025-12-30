-- users
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT CHECK(role IN ('admin','user')) NOT NULL,
  is_active BOOLEAN DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  last_login_at DATETIME
);

-- user_totp
CREATE TABLE IF NOT EXISTS user_totp (
  user_id INTEGER PRIMARY KEY,
  totp_secret TEXT NOT NULL,
  enabled BOOLEAN DEFAULT 0,
  verified_at DATETIME,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

-- transfers
CREATE TABLE IF NOT EXISTS transfers (
  id TEXT PRIMARY KEY,
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

-- upload_sessions
CREATE TABLE IF NOT EXISTS upload_sessions (
  id TEXT PRIMARY KEY,
  transfer_id TEXT NOT NULL,
  chunk_size INTEGER NOT NULL,
  total_chunks INTEGER NOT NULL,
  uploaded_chunks INTEGER DEFAULT 0,
  status TEXT CHECK(status IN ('active','completed','failed')),
  last_activity_at DATETIME,
  FOREIGN KEY(transfer_id) REFERENCES transfers(id)
);

-- transfer_permissions
CREATE TABLE IF NOT EXISTS transfer_permissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transfer_id TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  permission TEXT CHECK(permission IN ('read','manage')) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(transfer_id) REFERENCES transfers(id),
  FOREIGN KEY(user_id) REFERENCES users(id)
);
