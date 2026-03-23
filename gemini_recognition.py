import google.generativeai as genai
import PIL.Image
import os
import json
from dotenv import load_dotenv

load_dotenv("apikey.env")
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

def predict_menu(image_path):
    try:
        model = genai.GenerativeModel('models/gemini-3-flash-preview')
        img = PIL.Image.open(image_path)
        
        # プロンプトをアップデート
        prompt = (
            "あなたはプロの管理栄養士兼シェフです。画像から冷蔵庫の食材を特定し、"
            "それらを活用した献立を3つ提案してください。回答は必ず以下のJSON形式のみで出力してください。\n\n"
            "【重要な制約条件】\n"
            "1. 基本的な調味料（塩、砂糖、醤油、味噌、油、みりん、酒、酢、マヨネーズ、ケチャップ、出汁など）は全て揃っている前提で考えてください。\n"
            "2. したがって、それら調味料を『認識された食材』や『足りない食材』のリストに含めないでください。\n"
            "3. 『足りない食材』には、料理を完成させるために買い足しが必要な「メインの肉・魚・野菜」のみを記載してください。\n\n"
            "{\n"
            "  \"detected_ingredients\": [\"特定したメイン食材1\", \"食材2\"],\n"
            "  \"menus\": [\n"
            "    {\n"
            "      \"title\": \"料理名\",\n"
            "      \"instructions\": [\"工程1\", \"工程2\"],\n"
            "      \"missing_items\": [\"買い足しが必要なメイン食材\"],\n"
            "      \"calories\": \"〇〇kcal\",\n"
            "      \"nutrients\": [\"たんぱく質\", \"ビタミンC\"]\n"
            "    }\n"
            "  ]\n"
            "}"
        )
        
        response = model.generate_content([prompt, img])
        clean_json = response.text.replace('```json', '').replace('```', '').strip()
        return json.loads(clean_json)

    except Exception as e:
        print(f"Gemini Error: {e}")
        return {
            "detected_ingredients": ["解析エラー"],
            "menus": []
        }