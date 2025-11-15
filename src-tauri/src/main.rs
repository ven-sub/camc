// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;
mod db;
mod exports;

use std::sync::Mutex;
use tauri::Manager;

/// Creates the Tauri application builder with all plugins and commands registered
fn create_tauri_app() -> tauri::Builder<tauri::Wry> {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .setup(|app| {
            // Initialize database after app is set up (so we have access to app paths)
            let conn = db::init_db(&app.handle())
                .expect("Failed to initialize database");
            
            // Manage the database connection
            app.manage(Mutex::new(conn));
            
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::greet,
            commands::get_platform,
            commands::test_db_connection,
            exports::export_ics,
            exports::export_vcard,
            exports::get_ics_content,
            exports::get_vcard_content,
            exports::list_json_files,
            exports::read_json_file,
            exports::create_sample_events,
            exports::ensure_documents_placeholder
        ])
}

fn main() {
    create_tauri_app()
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
