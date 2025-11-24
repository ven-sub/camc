use tauri::AppHandle;
use crate::exports::get_export_directory;
use std::fs;
use base64::{Engine as _, engine::general_purpose};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ListItem {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub time: Option<String>,
    #[serde(rename = "item_number", skip_serializing_if = "Option::is_none")]
    pub item_number: Option<String>,
    pub theme: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub speaker: Option<String>,
    #[serde(rename = "type", skip_serializing_if = "Option::is_none")]
    pub item_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub duration: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub instructions: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PrintSettings {
    #[serde(rename = "pageSize")]
    pub page_size: String,
    pub orientation: String,
    pub margins: Margins,
    #[serde(rename = "fontSize")]
    pub font_size: f32,
    #[serde(rename = "viewMode")]
    pub view_mode: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Margins {
    pub top: f32,
    pub bottom: f32,
    pub left: f32,
    pub right: f32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GeneratePdfOxidizeRequest {
    pub items: Vec<ListItem>,
    pub settings: PrintSettings,
}

/// Generate PDF from web content
/// Receives PDF bytes (base64) from JavaScript library (html2pdf.js) and writes to file
#[tauri::command]
pub fn generate_pdf_from_web_content(
    app: AppHandle,
    pdf_base64: String,
) -> Result<String, String> {
    // Get export directory
    let export_dir = get_export_directory(&app)?;
    let file_path = export_dir.join("PrintList.pdf");

    // Validate input
    if pdf_base64.is_empty() {
        return Err("Received empty PDF data".to_string());
    }

    println!("Received PDF base64, length: {} characters", pdf_base64.len());

    // Decode base64 PDF bytes
    let pdf_bytes = general_purpose::STANDARD
        .decode(&pdf_base64)
        .map_err(|e| format!("Failed to decode base64 PDF: {} (input length: {})", e, pdf_base64.len()))?;

    if pdf_bytes.is_empty() {
        return Err("Decoded PDF bytes are empty".to_string());
    }

    println!("Decoded PDF bytes, size: {} bytes", pdf_bytes.len());

    // Write PDF bytes to file
    fs::write(&file_path, &pdf_bytes)
        .map_err(|e| format!("Failed to write PDF file: {} (tried to write {} bytes)", e, pdf_bytes.len()))?;

    println!("Successfully wrote PDF to: {}", file_path.display());

    Ok(file_path.to_string_lossy().to_string())
}

/// Generate PDF using oxidize-pdf from list items data
/// Creates a properly formatted PDF with table structure using oxidize-pdf crate
#[tauri::command]
pub fn generate_pdf_oxidize(
    app: AppHandle,
    request: GeneratePdfOxidizeRequest,
) -> Result<String, String> {
    let items = request.items;
    let settings = request.settings;
    use oxidize_pdf::{Document, Page, Font, Color};
    
    // Get export directory
    let export_dir = get_export_directory(&app)?;
    let file_path = export_dir.join("PrintList_Oxidize.pdf");

    // Create document
    let mut doc = Document::new();
    doc.set_title("Program Schedule");

    // Determine page type based on size and orientation
    let mut page = if settings.orientation == "landscape" {
        match settings.page_size.as_str() {
            "A4" => Page::a4_landscape(),
            "Legal" => Page::legal_landscape(),
            _ => Page::letter_landscape(), // Letter default
        }
    } else {
        match settings.page_size.as_str() {
            "A4" => Page::a4(),
            "Legal" => Page::legal(),
            _ => Page::letter(), // Letter default
        }
    };
    
    // Get page dimensions in points
    let page_width = page.width();
    let page_height = page.height();
    
    // Convert margins from mm to points (1mm = 2.83465 points)
    let margin_top = (settings.margins.top as f64) * 2.83465;
    let margin_bottom = (settings.margins.bottom as f64) * 2.83465;
    let margin_left = (settings.margins.left as f64) * 2.83465;
    let margin_right = (settings.margins.right as f64) * 2.83465;
    
    // Calculate content area
    let content_width = page_width - margin_left - margin_right;
    let content_height = page_height - margin_top - margin_bottom;
    
    // Font sizes
    let font_size = settings.font_size as f64;
    let header_font_size = font_size * 2.0;
    let meta_font_size = font_size * 0.83;
    let table_header_font_size = font_size * 0.92;
    let line_height = font_size * 1.5;
    let row_height = font_size * 1.8;
    
    // Column widths (as percentages of content width)
    let col_time_width = content_width * 0.10;
    let col_theme_width = content_width * 0.25;
    let col_speaker_width = content_width * 0.15;
    let col_type_width = content_width * 0.15;
    let col_instructions_width = content_width * 0.35;
    
    let mut y_pos = page_height - margin_top;
    
    // Add header
    let header_text = "Program Schedule";
    page.text()
        .set_font(Font::HelveticaBold, header_font_size)
        .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
        .at(margin_left, y_pos)
        .write(&header_text)
        .map_err(|e| format!("Failed to write header: {}", e))?;
    
    y_pos -= line_height * 2.0;
    
    // Add generation date
    let date_text = format!("Generated: {}", chrono::Local::now().format("%m/%d/%Y"));
    page.text()
        .set_font(Font::Helvetica, meta_font_size)
        .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
        .at(margin_left, y_pos)
        .write(&date_text)
        .map_err(|e| format!("Failed to write date: {}", e))?;
    
    y_pos -= line_height * 2.5;
    
    // Add intro text
    let intro_text = "This document contains the program schedule with detailed information for each item.";
    let intro_lines = wrap_text(&intro_text, content_width, font_size);
    for line in intro_lines {
        if y_pos < margin_bottom + line_height {
            doc.add_page(page);
            page = create_new_page(&settings);
            y_pos = page.height() - margin_top;
        }
        page.text()
            .set_font(Font::Helvetica, font_size)
            .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
            .at(margin_left, y_pos)
            .write(&line)
            .map_err(|e| format!("Failed to write intro: {}", e))?;
        y_pos -= line_height;
    }
    
    y_pos -= line_height;
    
    // Draw table header
    if y_pos < margin_bottom + row_height {
        doc.add_page(page);
        page = create_new_page(&settings);
        y_pos = page.height() - margin_top;
    }
    
    let header_y = y_pos;
    let mut x_pos = margin_left;
    
    // Draw header background and text
    page.graphics()
        .set_fill_color(oxidize_pdf::Color::rgb(0.96, 0.96, 0.96))
        .rect(x_pos, y_pos - row_height, content_width, row_height)
        .fill();
    
    // Header: Time
    page.text()
        .set_font(Font::HelveticaBold, table_header_font_size)
        .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
        .at(x_pos + 5.0, header_y - (row_height * 0.3))
        .write("Time")
        .map_err(|e| format!("Failed to write header: {}", e))?;
    x_pos += col_time_width;
    
    // Header: Theme
    page.text()
        .set_font(Font::HelveticaBold, table_header_font_size)
        .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
        .at(x_pos + 5.0, header_y - (row_height * 0.3))
        .write("Theme")
        .map_err(|e| format!("Failed to write header: {}", e))?;
    x_pos += col_theme_width;
    
    // Header: Speaker
    page.text()
        .set_font(Font::HelveticaBold, table_header_font_size)
        .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
        .at(x_pos + 5.0, header_y - (row_height * 0.3))
        .write("Speaker")
        .map_err(|e| format!("Failed to write header: {}", e))?;
    x_pos += col_speaker_width;
    
    // Header: Type
    page.text()
        .set_font(Font::HelveticaBold, table_header_font_size)
        .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
        .at(x_pos + 5.0, header_y - (row_height * 0.3))
        .write("Type")
        .map_err(|e| format!("Failed to write header: {}", e))?;
    x_pos += col_type_width;
    
    // Header: Instructions
    page.text()
        .set_font(Font::HelveticaBold, table_header_font_size)
        .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
        .at(x_pos + 5.0, header_y - (row_height * 0.3))
        .write("Instructions")
        .map_err(|e| format!("Failed to write header: {}", e))?;
    
    // Draw header border
    page.graphics()
        .set_stroke_color(oxidize_pdf::Color::rgb(0.2, 0.2, 0.2))
        .set_line_width(2.0)
        .move_to(margin_left, header_y - row_height)
        .line_to(margin_left + content_width, header_y - row_height)
        .stroke();
    
    y_pos -= row_height;
    
    // Add table rows
    for item in items {
        // Check if we need a new page
        let item_height = if settings.view_mode == "detailed" && item.instructions.is_some() {
            // Estimate height based on instructions length
            let inst_text = item.instructions.as_ref().unwrap();
            let inst_lines = wrap_text(inst_text, col_instructions_width, font_size);
            (inst_lines.len() as f64 * line_height).max(row_height)
        } else {
            row_height
        };
        
        if y_pos < margin_bottom + item_height {
            doc.add_page(page);
            page = create_new_page(&settings);
            y_pos = page.height() - margin_top;
        }
        
        let row_y = y_pos;
        let mut x_pos = margin_left;
        
        // Draw row border
        page.graphics()
            .set_stroke_color(oxidize_pdf::Color::rgb(0.9, 0.9, 0.9))
            .set_line_width(0.5)
            .move_to(margin_left, row_y - item_height)
            .line_to(margin_left + content_width, row_y - item_height)
            .stroke();
        
        // Time column
        if let Some(time) = &item.time {
            let time_lines = wrap_text(time, col_time_width - 10.0, font_size);
            let mut text_y = row_y - (row_height * 0.3);
            for line in time_lines {
                page.text()
                    .set_font(Font::Helvetica, font_size)
                    .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
                    .at(x_pos + 5.0, text_y)
                    .write(&line)
                    .map_err(|e| format!("Failed to write time: {}", e))?;
                text_y -= line_height;
            }
        }
        x_pos += col_time_width;
        
        // Theme column
        let theme_text = if let Some(item_num) = &item.item_number {
            format!("{}: {}", item_num, item.theme)
        } else {
            item.theme.clone()
        };
        let theme_lines = wrap_text(&theme_text, col_theme_width - 10.0, font_size);
        let mut text_y = row_y - (row_height * 0.3);
        for line in theme_lines {
            page.text()
                .set_font(Font::Helvetica, font_size)
                .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
                .at(x_pos + 5.0, text_y)
                .write(&line)
                .map_err(|e| format!("Failed to write theme: {}", e))?;
            text_y -= line_height;
        }
        x_pos += col_theme_width;
        
        // Speaker column
        if let Some(speaker) = &item.speaker {
            let speaker_lines = wrap_text(speaker, col_speaker_width - 10.0, font_size);
            let mut text_y = row_y - (row_height * 0.3);
            for line in speaker_lines {
                page.text()
                    .set_font(Font::Helvetica, font_size)
                    .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
                    .at(x_pos + 5.0, text_y)
                    .write(&line)
                    .map_err(|e| format!("Failed to write speaker: {}", e))?;
                text_y -= line_height;
            }
        }
        x_pos += col_speaker_width;
        
        // Type column
        let type_text = if let (Some(typ), Some(dur)) = (&item.item_type, &item.duration) {
            format!("{} ({})", typ, dur)
        } else if let Some(typ) = &item.item_type {
            typ.clone()
        } else {
            String::new()
        };
        if !type_text.is_empty() {
            let type_lines = wrap_text(&type_text, col_type_width - 10.0, font_size);
            let mut text_y = row_y - (row_height * 0.3);
            for line in type_lines {
                page.text()
                    .set_font(Font::Helvetica, font_size)
                    .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
                    .at(x_pos + 5.0, text_y)
                    .write(&line)
                    .map_err(|e| format!("Failed to write type: {}", e))?;
                text_y -= line_height;
            }
        }
        x_pos += col_type_width;
        
        // Instructions column (only in detailed view)
        if settings.view_mode == "detailed" {
            if let Some(instructions) = &item.instructions {
                let inst_lines = wrap_text(instructions, col_instructions_width - 10.0, font_size);
                let mut text_y = row_y - (row_height * 0.3);
                for line in inst_lines {
                    page.text()
                        .set_font(Font::Helvetica, font_size * 0.92)
                        .set_fill_color(Color::rgb(0.0, 0.0, 0.0)) // Black text
                        .at(x_pos + 5.0, text_y)
                        .write(&line)
                        .map_err(|e| format!("Failed to write instructions: {}", e))?;
                    text_y -= line_height;
                }
            }
        }
        
        y_pos -= item_height;
    }
    
    // Add the last page
    doc.add_page(page);
    
    // Save PDF
    doc.save(&file_path)
        .map_err(|e| format!("Failed to save PDF: {}", e))?;
    
    println!("Successfully created PDF using oxidize-pdf at: {}", file_path.display());
    
    Ok(file_path.to_string_lossy().to_string())
}

/// Create a new page based on settings
fn create_new_page(settings: &PrintSettings) -> oxidize_pdf::Page {
    if settings.orientation == "landscape" {
        match settings.page_size.as_str() {
            "A4" => oxidize_pdf::Page::a4_landscape(),
            "Legal" => oxidize_pdf::Page::legal_landscape(),
            _ => oxidize_pdf::Page::letter_landscape(),
        }
    } else {
        match settings.page_size.as_str() {
            "A4" => oxidize_pdf::Page::a4(),
            "Legal" => oxidize_pdf::Page::legal(),
            _ => oxidize_pdf::Page::letter(),
        }
    }
}

/// Wrap text to fit within a given width
fn wrap_text(text: &str, max_width: f64, font_size: f64) -> Vec<String> {
    // Estimate character width (approximate: font_size * 0.6 for average character)
    let char_width = font_size * 0.6;
    let max_chars = (max_width / char_width).max(10.0) as usize;
    
    let mut lines = Vec::new();
    let words: Vec<&str> = text.split_whitespace().collect();
    let mut current_line = String::new();
    
    for word in words {
        if current_line.is_empty() {
            current_line = word.to_string();
        } else if (current_line.len() + word.len() + 1) <= max_chars {
            current_line.push(' ');
            current_line.push_str(word);
        } else {
            lines.push(current_line);
            current_line = word.to_string();
        }
    }
    
    if !current_line.is_empty() {
        lines.push(current_line);
    }
    
    if lines.is_empty() {
        lines.push(text.to_string());
    }
    
    lines
}
