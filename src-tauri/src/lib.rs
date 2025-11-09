// Mobile entry point for iOS/Android builds
// This file is only used for mobile builds, desktop uses main.rs

mod commands;
mod db;
mod exports;

use std::sync::Mutex;

// Mobile entry point (for iOS/Android builds only)
#[cfg(mobile)]
#[tauri::mobile_entry_point]
fn main() {
    // Initialize database
    let conn = db::init_db().expect("Failed to initialize database");

    // Ensure a small placeholder exists in Documents so the Files app will show the app folder
    match exports::ensure_documents_placeholder() {
        Ok(path) => {
            // Best-effort informational print; on mobile this will appear in device logs
            println!("Created or verified placeholder file at: {}", path);
        }
        Err(err) => {
            eprintln!("Could not ensure placeholder file in Documents: {}", err);
        }
    }

    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .manage(Mutex::new(conn))
        .invoke_handler(tauri::generate_handler![
            commands::greet,
            commands::get_platform,
            commands::test_db_connection,
            exports::export_ics,
            exports::export_vcard,
            exports::get_ics_content,
            exports::get_vcard_content,
            // Also expose file-related commands on mobile (import/export/list)
            exports::list_json_files,
            exports::read_json_file,
            exports::create_sample_events,
            // Ensure placeholder so Files app shows the folder on device installs
            exports::ensure_documents_placeholder
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
