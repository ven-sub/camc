use std::fs;
use std::path::PathBuf;

/// Creates sample ICS calendar content
fn create_sample_ics_content() -> String {
    "BEGIN:VCALENDAR\r\n\
VERSION:2.0\r\n\
PRODID:-//Circuit Assistant//EN\r\n\
BEGIN:VEVENT\r\n\
UID:sample-event-001@circuitassistant.org\r\n\
DTSTAMP:20251109T120000Z\r\n\
DTSTART:20251115T100000Z\r\n\
DTEND:20251115T110000Z\r\n\
SUMMARY:Circuit Overseer Visit\r\n\
DESCRIPTION:Weekly meeting with Circuit Overseer talk\r\n\
LOCATION:Kingdom Hall\r\n\
STATUS:CONFIRMED\r\n\
END:VEVENT\r\n\
END:VCALENDAR\r\n".to_string()
}

/// Creates sample vCard contact content
fn create_sample_vcard_content() -> String {
    "BEGIN:VCARD\r\n\
VERSION:3.0\r\n\
FN:John Smith\r\n\
N:Smith;John;;;\r\n\
ORG:Kingdom Hall of Jehovah's Witnesses\r\n\
TITLE:Elder\r\n\
TEL;TYPE=CELL:+1-555-123-4567\r\n\
EMAIL:john.smith@example.com\r\n\
ADR;TYPE=HOME:;;123 Main Street;Anytown;CA;12345;USA\r\n\
NOTE:Circuit Overseer Contact\r\n\
END:VCARD\r\n".to_string()
}

#[tauri::command]
pub fn export_ics() -> Result<String, String> {
    // Get app data directory
    let app_dir = dirs::data_local_dir()
        .ok_or("Failed to get app data directory")?
        .join("org.circuitassistant.camc");
    
    // Create directory if it doesn't exist
    fs::create_dir_all(&app_dir).map_err(|e| e.to_string())?;
    
    // Create ICS file path
    let file_path = app_dir.join("sample_event.ics");
    
    // Get ICS content from helper function
    let ics_content = create_sample_ics_content();
    
    // Write to file
    fs::write(&file_path, ics_content).map_err(|e| e.to_string())?;
    
    // Return the file path as a string
    Ok(file_path.to_string_lossy().to_string())
}

#[tauri::command]
pub fn export_vcard() -> Result<String, String> {
    // Get app data directory
    let app_dir = dirs::data_local_dir()
        .ok_or("Failed to get app data directory")?
        .join("org.circuitassistant.camc");
    
    // Create directory if it doesn't exist
    fs::create_dir_all(&app_dir).map_err(|e| e.to_string())?;
    
    // Create vCard file path
    let file_path = app_dir.join("sample_contact.vcf");
    
    // Get vCard content from helper function
    let vcard_content = create_sample_vcard_content();
    
    // Write to file
    fs::write(&file_path, vcard_content).map_err(|e| e.to_string())?;
    
    // Return the file path as a string
    Ok(file_path.to_string_lossy().to_string())
}

