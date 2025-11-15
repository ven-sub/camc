use rusqlite::{Connection, Result};
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

#[allow(dead_code)]
pub fn init_db(app: &AppHandle) -> Result<Connection> {
    let db_path = get_db_path(app)?;
    let conn = Connection::open(db_path)?;

    // Database is ready for future tables
    // No tables needed yet, just the scaffolding

    Ok(conn)
}

#[allow(dead_code)]
fn get_db_path(app: &AppHandle) -> Result<PathBuf> {
    // Use Tauri's app_data_dir which works on all platforms including Android/iOS
    let mut path = app
        .path()
        .app_data_dir()
        .map_err(|e| rusqlite::Error::InvalidPath(format!("Failed to get app data dir: {}", e).into()))?;
    
    std::fs::create_dir_all(&path)
        .map_err(|e| rusqlite::Error::InvalidPath(format!("Failed to create data dir: {}", e).into()))?;
    
    path.push("camc.db");
    Ok(path)
}
