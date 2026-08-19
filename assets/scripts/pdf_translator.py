# -*- coding: utf-8 -*-
import os
import sys
import json
import re
import argparse
import fitz  # PyMuPDF
from deep_translator import GoogleTranslator

# Regex tiếng Trung
CHINESE_REGEX = re.compile(r'[\u4e00-\u9fff]')

def contains_chinese(text):
    if not isinstance(text, str):
        return False
    return bool(CHINESE_REGEX.search(text))

def translate_text_online(text, engine, target_lang="vi", api_key=None):
    if not text or not text.strip():
        return text
    try:
        if engine == "gemini" and api_key:
            import requests
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
            headers = {"Content-Type": "application/json"}
            prompt = f"Bạn là một biên dịch viên chuyên nghiệp. Hãy dịch đoạn văn bản sau đây sang tiếng Việt (hoặc ngôn ngữ mã \"{target_lang}\"). Chỉ trả về bản dịch, không giải thích gì thêm:\n\n{text}"
            data = {
                "contents": [{
                    "parts": [{"text": prompt}]
                }]
            }
            response = requests.post(url, headers=headers, json=data, timeout=10)
            if response.status_code == 200:
                result = response.json()
                translated = result['candidates'][0]['content']['parts'][0]['text'].strip()
                if translated.startswith('"') and translated.endswith('"'):
                    translated = translated[1:-1]
                return translated
            else:
                print(f"[WARN] Gemini API failed with status {response.status_code}, fallback to Google Free.", file=sys.stderr)
        
        return GoogleTranslator(source='auto', target=target_lang).translate(text)
    except Exception as e:
        print(f"[WARN] Translation error: {str(e)}", file=sys.stderr)
        return text

def process_pdf(src_path, dest_path, dict_data, engine, target_lang, api_key):
    doc = fitz.open(src_path)
    total_translated = 0
    
    # Tìm font Arial trên Windows để hỗ trợ hiển thị Tiếng Việt Unicode
    font_path = "C:/Windows/Fonts/arial.ttf"
    if not os.path.exists(font_path):
        # Thử một vài đường dẫn font khác nếu không thấy
        fallback_paths = [
            "C:/Windows/Fonts/tahoma.ttf",
            "C:/Windows/Fonts/times.ttf",
            "/System/Library/Fonts/Supplemental/Arial.ttf",  # macOS
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf" # Linux
        ]
        for path in fallback_paths:
            if os.path.exists(path):
                font_path = path
                break
                
    normalized_dict = {str(k).strip().lower(): str(v).strip() for k, v in dict_data.items() if k}
    
    for page_idx in range(len(doc)):
        page = doc[page_idx]
        
        # Lấy các khối text trên trang
        # get_text("blocks") trả về list các tuple: (x0, y0, x1, y1, "text", block_no, block_type)
        blocks = page.get_text("blocks")
        
        for block in blocks:
            x0, y0, x1, y1, text, block_no, block_type = block
            
            # Chỉ xử lý văn bản và khối có chữ tiếng Trung (hoặc tiếng Anh nếu người dùng dịch Anh-Việt)
            if block_type == 0 and text and (contains_chinese(text) or (target_lang == 'vi' and not contains_chinese(text) and len(text.strip()) > 1)):
                val_str = text.strip()
                val_lower = val_str.lower()
                
                # Bỏ qua các chuỗi chỉ có số hoặc ký tự đặc biệt
                if not re.search(r'[a-zA-Z\u4e00-\u9fff]', val_str):
                    continue
                
                # 1. Tra từ điển
                translated = None
                if val_lower in normalized_dict:
                    translated = normalized_dict[val_lower]
                else:
                    # Tra một phần từ điển
                    matched_dict = False
                    for key_word, trans_word in normalized_dict.items():
                        if key_word in val_lower:
                            pattern = re.compile(re.escape(key_word), re.IGNORECASE)
                            val_str = pattern.sub(trans_word, val_str)
                            matched_dict = True
                    
                    if matched_dict:
                        translated = val_str
                
                # 2. Dịch online nếu chưa được dịch
                if not translated or (contains_chinese(translated) if contains_chinese(text) else False):
                    translated = translate_text_online(translated or val_str, engine, target_lang, api_key)
                
                if translated and translated != text.strip():
                    rect = fitz.Rect(x0, y0, x1, y1)
                    
                    # Che chữ cũ bằng một hình chữ nhật màu trắng
                    # (Để tạo cảm giác đè chữ tự nhiên)
                    page.draw_rect(rect, color=(1, 1, 1), fill=(1, 1, 1), overlay=True)
                    
                    # Xác định cỡ chữ phù hợp với khung
                    # Tính toán sơ bộ: dựa trên số ký tự và kích thước khung
                    area = rect.width * rect.height
                    char_count = len(translated)
                    fontsize = 9
                    if char_count > 0:
                        import math
                        fontsize = math.sqrt(area / (char_count * 0.6))
                        fontsize = max(7, min(fontsize, 12)) # giới hạn từ 7 đến 12
                    
                    # Vẽ bản dịch đè lên
                    try:
                        if os.path.exists(font_path):
                            page.insert_textbox(rect, translated, fontfile=font_path, fontname="Arial", fontsize=fontsize, color=(0, 0, 0))
                        else:
                            # Không có font ngoài thì dùng Helvetica mặc định (có thể lỗi tiếng Việt Unicode)
                            page.insert_textbox(rect, translated, fontname="helv", fontsize=fontsize, color=(0, 0, 0))
                        total_translated += 1
                    except Exception as e:
                        print(f"[WARN] Draw text box failed on page {page_idx}: {str(e)}", file=sys.stderr)
                        
    doc.save(dest_path)
    doc.close()
    
    return {
        "success": True,
        "total_translated": total_translated,
        "remaining_chinese_count": 0,
        "remaining_cells": []
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="JA PDF Document Translator Tool")
    parser.add_argument("--src", required=True, help="Path to source PDF file")
    parser.add_argument("--dest", required=True, help="Path to destination PDF file")
    parser.add_argument("--dict", default="{}", help="JSON string of translation dictionary")
    parser.add_argument("--engine", default="google", help="Translation engine (google, gemini)")
    parser.add_argument("--lang", default="vi", help="Target language code")
    parser.add_argument("--key", default="", help="API Key for translation engine")
    
    args = parser.parse_args()
    
    try:
        try:
            dict_data = json.loads(args.dict)
        except Exception:
            dict_data = {}
            
        result = process_pdf(
            src_path=args.src,
            dest_path=args.dest,
            dict_data=dict_data,
            engine=args.engine,
            target_lang=args.lang,
            api_key=args.key
        )
        print(json.dumps(result, ensure_ascii=False))
    except Exception as e:
        error_res = {
            "success": False,
            "error": str(e)
        }
        print(json.dumps(error_res, ensure_ascii=False))
        sys.exit(1)
