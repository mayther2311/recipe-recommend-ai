from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
from gemini_recognition import predict_menu

app = FastAPI()

# Flutter Webとの通信を許可
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

if not os.path.exists("static"):
    os.makedirs("static")

@app.post("/upload/")
async def upload_image(file: UploadFile = File(...)):
    # 一時保存パス
    file_path = f"static/{file.filename}"
    
    try:
        # 1. 画像を保存
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # 2. Geminiで解析（複数の献立を取得）
        result = predict_menu(file_path)
        return result

    finally:
        # 3. 解析が終わったら即座に削除（ストレージ節約）
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f"INFO: {file_path} を自動削除しました。")

@app.get("/")
def index():
    return {"message": "Menu AI Server is running"}