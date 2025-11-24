use rusqlite::Connection;
use std::sync::Mutex;
use std::fs;
use std::path::PathBuf;
use serde_json::Value;
use tauri::{AppHandle, Manager};

// Global database connection type
#[allow(dead_code)]
pub type DbConnection = Mutex<Connection>;

// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
#[tauri::command]
pub fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[tauri::command]
pub fn test_db_connection() -> String {
    "Database ready: camc.db".to_string()
}

#[tauri::command]
pub fn get_platform() -> String {
    #[cfg(target_os = "windows")]
    return "windows".to_string();
    #[cfg(target_os = "macos")]
    return "macos".to_string();
    #[cfg(target_os = "linux")]
    return "linux".to_string();
    #[cfg(target_os = "android")]
    return "android".to_string();
    #[cfg(target_os = "ios")]
    return "ios".to_string();
}

/// Get the data directory (same as export directory)
fn get_data_directory(app: &AppHandle) -> Result<PathBuf, String> {
    // Reuse the export directory logic from exports module
    // On iOS/Android: Returns app's Documents directory
    // On Desktop: Returns app's data directory
    #[cfg(any(target_os = "ios", target_os = "android"))]
    {
        let doc_dir = app
            .path()
            .document_dir()
            .map_err(|e| format!("Failed to get document directory: {}", e))?;
        fs::create_dir_all(&doc_dir).map_err(|e| e.to_string())?;
        Ok(doc_dir)
    }
    
    #[cfg(not(any(target_os = "ios", target_os = "android")))]
    {
        let app_dir = app
            .path()
            .app_data_dir()
            .map_err(|e| format!("Failed to get app data directory: {}", e))?;
        fs::create_dir_all(&app_dir).map_err(|e| e.to_string())?;
        Ok(app_dir)
    }
}

/// Get the file path for a model's data file
fn get_model_data_path(app: &AppHandle, model_name: &str) -> Result<PathBuf, String> {
    let data_dir = get_data_directory(app)?;
    let filename = format!("{}-data.json", model_name);
    Ok(data_dir.join(filename))
}

/// Read model data from JSON file
/// Returns an empty array if file doesn't exist
#[tauri::command]
pub fn read_model_data(app: AppHandle, model_name: String) -> Result<Vec<Value>, String> {
    let file_path = get_model_data_path(&app, &model_name)?;
    
    // If file doesn't exist, return empty array
    if !file_path.exists() {
        return Ok(Vec::new());
    }
    
    // Read and parse JSON
    let contents = fs::read_to_string(&file_path)
        .map_err(|e| format!("Failed to read file: {}", e))?;
    
    let data: Vec<Value> = serde_json::from_str(&contents)
        .map_err(|e| format!("Failed to parse JSON: {}", e))?;
    
    Ok(data)
}

/// Write model data to JSON file
#[tauri::command]
pub fn write_model_data(app: AppHandle, model_name: String, data: Vec<Value>) -> Result<String, String> {
    let file_path = get_model_data_path(&app, &model_name)?;
    
    // Serialize to JSON with pretty printing
    let json = serde_json::to_string_pretty(&data)
        .map_err(|e| format!("Failed to serialize JSON: {}", e))?;
    
    // Write to file
    fs::write(&file_path, json)
        .map_err(|e| format!("Failed to write file: {}", e))?;
    
    Ok(file_path.to_string_lossy().to_string())
}

/// List all model data files (*-data.json) in the data directory
#[tauri::command]
pub fn list_model_data_files(app: AppHandle) -> Result<Vec<String>, String> {
    let data_dir = get_data_directory(&app)?;
    let mut model_files = Vec::new();
    
    // Read directory entries
    let entries = fs::read_dir(&data_dir)
        .map_err(|e| format!("Failed to read directory: {}", e))?;
    
    for entry in entries {
        let entry = entry.map_err(|e| format!("Failed to read entry: {}", e))?;
        let path = entry.path();
        
        // Check if it's a file and matches the pattern *-data.json
        if path.is_file() {
            if let Some(file_name) = path.file_name() {
                if let Some(name_str) = file_name.to_str() {
                    if name_str.ends_with("-data.json") {
                        // Extract model name (remove -data.json suffix)
                        let model_name = name_str
                            .strip_suffix("-data.json")
                            .unwrap_or(name_str)
                            .to_string();
                        model_files.push(model_name);
                    }
                }
            }
        }
    }
    
    // Sort alphabetically
    model_files.sort();
    
    Ok(model_files)
}

