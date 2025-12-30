import sqlite3
import os
import glob
import shutil
from datetime import datetime

DB_PATH = "database/database.db"
SCHEMA_PATH = "database/schemas.sql"
BACKUP_DIR = "database/backups"

REQUIRED_TABLES = ["users", "user_totp", "transfers", "upload_sessions", "transfer_permissions"]

def get_latest_backup():
    backups = glob.glob(os.path.join(BACKUP_DIR, "*.db"))
    if not backups:
        return None
    backups.sort(key=os.path.getmtime, reverse=True)
    return backups[0]

def verify_tables(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    existing = {row[0] for row in cursor.fetchall()}
    missing = [t for t in REQUIRED_TABLES if t not in existing]
    return missing

def init_db():
    # Si no existe la base, crearla
    if not os.path.exists(DB_PATH):
        print("No existe database.db, creando nueva...")
        conn = sqlite3.connect(DB_PATH)
    else:
        conn = sqlite3.connect(DB_PATH)

    # Verificar tablas
    missing = verify_tables(conn)
    if missing:
        print(f"Faltan tablas: {missing}")
        latest_backup = get_latest_backup()
        if latest_backup:
            print(f"Restaurando desde backup: {latest_backup}")
            conn.close()
            shutil.copy(latest_backup, DB_PATH)
            conn = sqlite3.connect(DB_PATH)
        else:
            print("No hay backup disponible, se regenerará estructura.")

    # Ejecutar schemas.sql para asegurar estructura
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        sql_script = f.read()
    conn.executescript(sql_script)
    conn.commit()
    conn.close()
    print("Base de datos inicializada/verificada correctamente.")

if __name__ == "__main__":
    init_db()
