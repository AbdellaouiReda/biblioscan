"""BiblioScan FastAPI server - Main application entry point"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi import File, UploadFile
import uvicorn

# Import controllers
from controllers import upload_controller, detection_controller

# =========================================================
#  APP CONFIGURATION
# =========================================================
app = FastAPI(title="BiblioScan Détection Serveur", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================================================
#  ROUTES
# =========================================================
@app.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    """Upload image endpoint"""
    return await upload_controller.upload_image(file)

@app.post("/detect")
async def detect(conf: float = 0.6, iou: float = 0.5):
    """Detect books endpoint"""
    return await detection_controller.detect(conf=conf, iou=iou)

@app.post("/detect_and_ocr")
async def detect_and_ocr(conf: float = 0.6, iou: float = 0.5):
    """Detect books and run OCR endpoint"""
    return await detection_controller.detect_and_ocr(conf=conf, iou=iou)

@app.post("/detect_and_ocr_and_agent")
async def detect_and_ocr_and_agent(conf: float = 0.6, iou: float = 0.5):
    """Detect books, run OCR, and resolve titles using agents"""
    return await detection_controller.detect_and_ocr_and_agent(conf=conf, iou=iou)

@app.get("/debug_crops/{filename}")
async def serve_crop(filename: str):
    """Serve crop images for debugging"""
    return await detection_controller.serve_crop(filename)

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    """Web interface"""
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
            <button id="detectOcrAgentBtn" onclick="detectAndOcrAndAgentBooks()" disabled>🤖🔍📝 Détecter + OCR + Agent</button>
        </div>
        
        <p id="status"></p>
        <div id="results"></div>
        <div id="ocrResults"></div>

        <script>
        const status = document.getElementById("status");
        const detectBtn = document.getElementById("detectBtn");
        const detectOcrBtn = document.getElementById("detectOcrBtn");
        const detectOcrAgentBtn = document.getElementById("detectOcrAgentBtn");
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
            detectOcrAgentBtn.disabled = false;
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

        async function detectAndOcrAndAgentBooks() {
            if (!imageUploaded) return;
            status.innerText = "🤖🔍📝 Détection, OCR et résolution par agent en cours...";
            detectOcrAgentBtn.disabled = true;
            const res = await fetch("/detect_and_ocr_and_agent", {method:"POST"});
            const data = await res.json();
            status.innerText = "✅ Détection, OCR et résolution terminés";
            detectOcrAgentBtn.disabled = false;
            
            if (data.num_books === 0) {
                document.getElementById("results").innerHTML = "<h3>❌ Aucun livre détecté</h3>";
                return;
            }
            
            let booksHtml = "";
            data.books.forEach(book => {
                let confidenceClass = book.ocr_quality.toLowerCase();
                let agentConfidenceClass = book.agent_confidence >= 70 ? "excellent" : 
                                         book.agent_confidence >= 50 ? "good" : 
                                         book.agent_confidence >= 30 ? "fair" : "poor";
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
                            <strong>Texte OCR extrait :</strong><br>
                            "${book.text || 'Aucun texte détecté'}"
                        </div>
                        
                        ${book.resolved_title ? `
                        <div class="ocr-text" style="background:#fff3cd; border:2px solid #ffc107;">
                            <strong>🤖 Titre résolu par l'agent :</strong><br>
                            "<strong style="font-size:20px; color:#006666;">${book.resolved_title}</strong>"
                        </div>
                        ` : ''}
                        
                        ${book.google_books_found && book.google_books_info ? `
                        <div class="ocr-text" style="background:#d4edda; border:2px solid #28a745;">
                            <strong>📚 Vérification Google Books :</strong><br>
                            <div style="margin-top:10px;">
                                ${book.google_books_info.authors && book.google_books_info.authors.length > 0 ? `
                                    <div><strong>Auteur(s):</strong> ${book.google_books_info.authors.join(', ')}</div>
                                ` : ''}
                                ${book.google_books_info.published_date ? `
                                    <div><strong>Publié:</strong> ${book.google_books_info.published_date}</div>
                                ` : ''}
                                ${book.google_books_info.categories && book.google_books_info.categories.length > 0 ? `
                                    <div><strong>Catégories:</strong> ${book.google_books_info.categories.slice(0, 3).join(', ')}</div>
                                ` : ''}
                                ${book.google_books_info.average_rating > 0 ? `
                                    <div><strong>Note:</strong> ${book.google_books_info.average_rating}/5 (${book.google_books_info.ratings_count} avis)</div>
                                ` : ''}
                                ${book.google_books_info.info_link ? `
                                    <div style="margin-top:8px;">
                                        <a href="${book.google_books_info.info_link}" target="_blank" style="color:#006666; text-decoration:underline;">
                                            🔗 Voir sur Google Books
                                        </a>
                                    </div>
                                ` : ''}
                            </div>
                        </div>
                        ` : book.google_books_verification ? `
                        <div class="ocr-text" style="background:#fff3cd; border:2px solid #ffc107;">
                            <strong>📚 Vérification Google Books :</strong><br>
                            <div style="margin-top:10px; white-space:pre-line;">${book.google_books_verification}</div>
                        </div>
                        ` : ''}
                        
                        <div>
                            <span class="confidence ${confidenceClass}">
                                OCR Confiance : ${book.ocr_confidence}% (${book.ocr_quality})
                            </span>
                            <span style="margin-left:10px; color:#666;">
                                Détection YOLO : ${(book.detection_confidence * 100).toFixed(1)}%
                            </span>
                            ${book.resolved_title ? `
                            <span class="confidence ${agentConfidenceClass}" style="margin-left:10px;">
                                Agent Confiance : ${book.agent_confidence}%
                            </span>
                            ` : ''}
                            ${book.google_books_found ? `
                            <span class="confidence excellent" style="margin-left:10px;">
                                ✅ Google Books
                            </span>
                            ` : ''}
                        </div>
                        
                        ${book.agent_reasoning ? `
                            <div style="margin-top:10px; padding:10px; background:#f8f9fa; border-radius:5px; font-size:14px; color:#666;">
                                <strong>💭 Raisonnement de l'agent :</strong><br>
                                ${book.agent_reasoning}
                            </div>
                        ` : ''}
                        
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
                    <h3>📚 ${data.num_books} livre(s) détecté(s), analysé(s) et résolu(s)</h3>
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
    print(" Serveur sur http://localhost:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)
