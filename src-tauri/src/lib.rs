// Mobile entry point for iOS/Android builds
// This file is only used for mobile builds, desktop uses main.rs

mod commands;
mod db;
mod exports;
mod pdf_exports;
mod print_exports;

use std::sync::Mutex;
use tauri::Manager;

// Mobile entry point (for iOS/Android builds only)
#[cfg(mobile)]
#[tauri::mobile_entry_point]
fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .setup(|app| {
            // Initialize database with AppHandle
            let conn = db::init_db(&app.handle())
                .expect("Failed to initialize database");
            app.manage(Mutex::new(conn));

            // Ensure a small placeholder exists in Documents so the Files app will show the app folder
            match exports::ensure_documents_placeholder(app.handle().clone()) {
                Ok(path) => {
                    println!("Created or verified placeholder file at: {}", path);
                }
                Err(err) => {
                    eprintln!("Could not ensure placeholder file in Documents: {}", err);
                }
            }

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
            // Also expose file-related commands on mobile (import/export/list)
            exports::list_json_files,
            exports::read_json_file,
            exports::create_sample_events,
            // Ensure placeholder so Files app shows the folder on device installs
            exports::ensure_documents_placeholder,
            // PDF generation commands
            pdf_exports::generate_pdf_printpdf,
            pdf_exports::generate_pdf_lopdf,
            pdf_exports::generate_pdf_genpdf,
            // Print preview PDF generation commands
            print_exports::generate_pdf_from_web_content,
            print_exports::generate_pdf_oxidize
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
