import os
import cv2
import numpy as np
import torch
import easyocr
from fastapi import FastAPI, File, UploadFile, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, FileResponse
from ultralytics import YOLO

# =========================================================
#  CONFIG
# =========================================================
app = FastAPI(title=" BiblioScan Détection Serveur", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================================================
#  YOLO
# =========================================================
MODEL_PATH = "./models/bookshelf_best.pt"
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
print(f" Device : {DEVICE}")

model = YOLO(MODEL_PATH)
model.to(DEVICE)
print(f" YOLO chargé depuis {MODEL_PATH}")

# =========================================================
#  EASYOCR
# =========================================================
print(" Initialisation EasyOCR...")
reader = easyocr.Reader(['fr', 'en'], gpu=(DEVICE == "cuda"), verbose=False)
print(f" EasyOCR chargé (GPU: {DEVICE == 'cuda'})")

# =========================================================
#  CHEMINS
# =========================================================
UPLOAD_PATH = "uploaded.jpg"
os.makedirs("debug_crops", exist_ok=True)
DEBUG_IMG_PATH = "debug_crops/debug_image.jpg"
ORIGINAL_PATH = "debug_crops/original.jpg"

# =========================================================
#  UPLOAD
# =========================================================
@app.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    content = await file.read()
    with open(UPLOAD_PATH, "wb") as f:
        f.write(content)
    img = cv2.imread(UPLOAD_PATH)
    cv2.imwrite(ORIGINAL_PATH, img)
    return {"message": " Image uploadée avec succès", "path": UPLOAD_PATH}

# =========================================================
#  DÉTECTION DES LIVRES
# =========================================================
@app.post("/detect")
async def detect(conf: float = 0.6, iou: float = 0.5):
    img = cv2.imread(UPLOAD_PATH)
    results = model.predict(img, conf=conf, iou=iou, imgsz=640, device=DEVICE, verbose=False)[0]

    annotated = img.copy()
    for box, score, cls in zip(results.boxes.xyxy.cpu().numpy(),
                               results.boxes.conf.cpu().numpy(),
                               results.boxes.cls.cpu().numpy()):
        x1, y1, x2, y2 = map(int, box)
        label = f"{results.names[int(cls)]} ({score:.2f})"
        cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 255, 0), 3)
        cv2.putText(annotated, label, (x1, max(25, y1-10)),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255,255,255), 2)

    cv2.imwrite(DEBUG_IMG_PATH, annotated)
    return {
        "num_books": len(results.boxes),
        "original_image": "/debug_crops/original.jpg",
        "annotated_image": "/debug_crops/debug_image.jpg"
    }

# =========================================================
#  OCR HELPER FUNCTIONS
# =========================================================
def preprocess_image(img):
    """Preprocess image for OCR: grayscale + contrast enhancement"""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    enhanced = cv2.equalizeHist(gray)
    return enhanced

def clean_text(results):
    """Clean and format OCR text"""
    if not results:
        return ""
    texts = [item[1] for item in results]
    text = ' '.join(texts)
    text = ' '.join(text.split())
    text = text.title()
    return text

def calculate_confidence(results):
    """Calculate average confidence from OCR results"""
    if not results:
        return 0.0
    confidences = [item[2] for item in results]
    return sum(confidences) / len(confidences)

def get_confidence_label(confidence):
    """Get quality label based on confidence score"""
    if confidence >= 0.9:
        return "Excellent"
    elif confidence >= 0.7:
        return "Good"
    elif confidence >= 0.5:
        return "Fair"
    else:
        return "Poor"


@app.get("/debug_crops/{filename}")
async def serve_crop(filename: str):
    return FileResponse(os.path.join("debug_crops", filename))

# =========================================================
#  DETECT BOOKS + OCR PER BOOK
# =========================================================
@app.post("/detect_and_ocr")
async def detect_and_ocr(conf: float = 0.6, iou: float = 0.5):
    """Detect books with YOLO and run OCR on each detected book individually"""
    img = cv2.imread(UPLOAD_PATH)
    
    # Run YOLO detection
    results = model.predict(img, conf=conf, iou=iou, imgsz=640, device=DEVICE, verbose=False)[0]
    
    if len(results.boxes) == 0:
        return {
            "num_books": 0,
            "books": [],
            "annotated_image": None
        }
    
    books_data = []
    annotated = img.copy()
    
    # Process each detected book
    for idx, (box, score, cls) in enumerate(zip(
        results.boxes.xyxy.cpu().numpy(),
        results.boxes.conf.cpu().numpy(),
        results.boxes.cls.cpu().numpy()
    )):
        x1, y1, x2, y2 = map(int, box)
        
        # Crop the book region
        book_crop = img[y1:y2, x1:x2]
        
        # Save crop for debugging
        crop_path = f"debug_crops/book_{idx}.jpg"
        cv2.imwrite(crop_path, book_crop)
        
        # Preprocess and run OCR on this specific book
        enhanced_crop = preprocess_image(book_crop)
        ocr_results = reader.readtext(enhanced_crop)
        
        # Process OCR results for this book
        cleaned_text = clean_text(ocr_results)
        avg_confidence = calculate_confidence(ocr_results)
        quality = get_confidence_label(avg_confidence)
        
        # Format detections for this book
        detections = []
        for bbox, text, conf in ocr_results:
            detections.append({
                "text": text,
                "confidence": round(conf * 100, 2),
                "bbox": [[float(x), float(y)] for x, y in bbox]
            })
        
        # Store book data
        book_info = {
            "book_id": idx,
            "bbox": [int(x1), int(y1), int(x2), int(y2)],
            "detection_confidence": float(score),
            "class": results.names[int(cls)],
            "text": cleaned_text,
            "ocr_confidence": round(avg_confidence * 100, 2) if ocr_results else 0.0,
            "ocr_quality": quality,
            "num_text_detections": len(ocr_results),
            "text_detections": detections,
            "crop_image": f"/debug_crops/book_{idx}.jpg"
        }
        books_data.append(book_info)
        
        # Draw on annotated image
        cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 255, 0), 3)
        label = f"Book {idx}: {cleaned_text[:20]}..." if cleaned_text else f"Book {idx}"
        cv2.putText(annotated, label, (x1, max(25, y1-10)),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        
        # Also draw OCR regions on the crop
        book_crop_annotated = book_crop.copy()
        for bbox, text, conf in ocr_results:
            points = np.array(bbox).astype(np.int32)
            cv2.polylines(book_crop_annotated, [points], True, (0, 255, 0), 2)
        
        crop_annotated_path = f"debug_crops/book_{idx}_ocr.jpg"
        cv2.imwrite(crop_annotated_path, book_crop_annotated)
        book_info["crop_image_annotated"] = f"/debug_crops/book_{idx}_ocr.jpg"
    
    # Save overall annotated image
    annotated_path = "debug_crops/all_books_detected.jpg"
    cv2.imwrite(annotated_path, annotated)
    
    return {
        "num_books": len(results.boxes),
        "books": books_data,
        "annotated_image": "/debug_crops/all_books_detected.jpg",
        "original_image": "/debug_crops/original.jpg"
    }

# =========================================================
#  INTERFACE WEB SIMPLE
# =========================================================
@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    html = """
    <html>
    <head>
        <title>BiblioScan - Détection & OCR</title>
        <style>
            body { font-family: 'Segoe UI', sans-serif; text-align:center; background:#f5f6fa; color:#222; padding:20px; }
            h2 { color:#006666; }
            button { background:#008080; color:white; padding:10px 20px; border:none; border-radius:8px; cursor:pointer; margin:5px; font-size:14px; }
            button:hover { background:#009999; }
            button:disabled { background:#ccc; cursor:not-allowed; }
            .images { display:flex; justify-content:center; gap:25px; margin-top:25px; flex-wrap:wrap; }
            .image-container { text-align:center; }
            img { border-radius:10px; box-shadow:0 3px 8px rgba(0,0,0,0.2); max-width:400px; }
            #status { font-weight:bold; color:#008080; margin:15px 0; }
            .ocr-results { background:white; border-radius:10px; padding:20px; margin:20px auto; max-width:800px; box-shadow:0 3px 8px rgba(0,0,0,0.1); }
            .ocr-text { font-size:18px; margin:15px 0; padding:15px; background:#e8f8f5; border-radius:8px; font-style:italic; }
            .confidence { display:inline-block; padding:5px 15px; border-radius:20px; font-weight:bold; margin:10px 5px; }
            .excellent { background:#2ecc71; color:white; }
            .good { background:#3498db; color:white; }
            .fair { background:#f39c12; color:white; }
            .poor { background:#e74c3c; color:white; }
            .detections { text-align:left; margin-top:15px; }
            .detection-item { background:#f8f9fa; padding:8px; margin:5px 0; border-radius:5px; border-left:3px solid #008080; }
            .button-group { margin:15px 0; }
        </style>
    </head>
    <body>
        <h2>📚 BiblioScan - Détection & OCR de livres</h2>
        <form id="uploadForm">
            <input type="file" id="fileInput" accept="image/*" required>
            <button type="submit">⬆️ Uploader l'image</button>
        </form>
        
        <div class="button-group">
            <button id="detectBtn" onclick="detectBooks()" disabled>🔍 Détecter les livres</button>
            <button id="detectOcrBtn" onclick="detectAndOcrBooks()" disabled>🔍📝 Détecter + OCR par livre</button>
        </div>
        
        <p id="status"></p>
        <div id="results"></div>
        <div id="ocrResults"></div>

        <script>
        const status = document.getElementById("status");
        const detectBtn = document.getElementById("detectBtn");
        const detectOcrBtn = document.getElementById("detectOcrBtn");
        let imageUploaded = false;

        document.getElementById("uploadForm").onsubmit = async (e) => {
            e.preventDefault();
            let file = document.getElementById("fileInput").files[0];
            let form = new FormData();
            form.append("file", file);
            status.innerText = "⏳ Upload en cours...";
            await fetch("/upload", {method:"POST", body:form});
            status.innerText = "✅ Image uploadée avec succès !";
            imageUploaded = true;
            detectBtn.disabled = false;
            detectOcrBtn.disabled = false;
            document.getElementById("results").innerHTML = "";
            document.getElementById("ocrResults").innerHTML = "";
        };

        async function detectBooks() {
            if (!imageUploaded) return;
            status.innerText = "🔍 Détection en cours...";
            detectBtn.disabled = true;
            const res = await fetch("/detect", {method:"POST"});
            const data = await res.json();
            status.innerText = "✅ Détection terminée";
            detectBtn.disabled = false;
            document.getElementById("results").innerHTML = `
                <div class='images'>
                    <div class='image-container'>
                        <h3>Image originale</h3>
                        <img src="${data.original_image}?t=${Date.now()}" width="400">
                    </div>
                    <div class='image-container'>
                        <h3>Livres détectés</h3>
                        <img src="${data.annotated_image}?t=${Date.now()}" width="400">
                    </div>
                </div>
                <h3>📚 Nombre de livres détectés : ${data.num_books}</h3>`;
        }

        async function detectAndOcrBooks() {
            if (!imageUploaded) return;
            status.innerText = "🔍📝 Détection et OCR par livre en cours...";
            detectOcrBtn.disabled = true;
            const res = await fetch("/detect_and_ocr", {method:"POST"});
            const data = await res.json();
            status.innerText = "✅ Détection et OCR terminés";
            detectOcrBtn.disabled = false;
            
            if (data.num_books === 0) {
                document.getElementById("results").innerHTML = "<h3>❌ Aucun livre détecté</h3>";
                return;
            }
            
            let booksHtml = "";
            data.books.forEach(book => {
                let confidenceClass = book.ocr_quality.toLowerCase();
                booksHtml += `
                    <div class="ocr-results" style="margin:20px auto;">
                        <h3>📕 Livre ${book.book_id + 1}</h3>
                        <div style="display:flex; gap:15px; justify-content:center; flex-wrap:wrap; margin:15px 0;">
                            <div>
                                <h4>Crop original</h4>
                                <img src="${book.crop_image}?t=${Date.now()}" style="max-width:250px;">
                            </div>
                            <div>
                                <h4>Détections OCR</h4>
                                <img src="${book.crop_image_annotated}?t=${Date.now()}" style="max-width:250px;">
                            </div>
                        </div>
                        
                        <div class="ocr-text">
                            <strong>Texte extrait :</strong><br>
                            "${book.text || 'Aucun texte détecté'}"
                        </div>
                        
                        <div>
                            <span class="confidence ${confidenceClass}">
                                OCR Confiance : ${book.ocr_confidence}% (${book.ocr_quality})
                            </span>
                            <span style="margin-left:10px; color:#666;">
                                Détection YOLO : ${(book.detection_confidence * 100).toFixed(1)}%
                            </span>
                        </div>
                        
                        ${book.text_detections.length > 0 ? `
                            <div class="detections">
                                <h4>Détails (${book.num_text_detections} détections) :</h4>
                                ${book.text_detections.map((d, i) => `
                                    <div class="detection-item">
                                        <strong>${i+1}.</strong> "${d.text}" 
                                        <span style="float:right; color:#008080;">${d.confidence}%</span>
                                    </div>
                                `).join('')}
                            </div>
                        ` : ''}
                    </div>
                `;
            });
            
            document.getElementById("results").innerHTML = `
                <div style="margin:20px 0;">
                    <h3>📚 ${data.num_books} livre(s) détecté(s) et analysé(s)</h3>
                    <div style="margin:15px 0;">
                        <img src="${data.annotated_image}?t=${Date.now()}" width="600" style="border-radius:10px;">
                    </div>
                </div>
            `;
            
            document.getElementById("ocrResults").innerHTML = booksHtml;
        }
        </script>
    </body>
    </html>
    """
    return HTMLResponse(html)

# =========================================================
#  RUN
# =========================================================
if __name__ == "__main__":
    import uvicorn
    print(" Serveur sur http://localhost:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)
