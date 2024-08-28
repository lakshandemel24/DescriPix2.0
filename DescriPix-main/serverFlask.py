from flask import Flask, request, jsonify
from transformers import AutoModel, AutoProcessor  # Modificato qui
import torch
from PIL import Image
import io
import base64
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Carica il modello e il processor
model_name = "unum-cloud/uform-gen2-qwen-500m"
model = AutoModel.from_pretrained(model_name, trust_remote_code=True)
processor = AutoProcessor.from_pretrained(model_name, trust_remote_code=True)  # Modificato qui
model.eval()  # Imposta il modello in modalità valutazione

@app.route('/predict', methods=['POST'])
def predict():
    content = request.json
    text = content['text']
    image_data = content['image'].split(",")[1]  # Rimuovi il prefisso base64

    # Converte l'immagine da base64 a PIL Image
    image = Image.open(io.BytesIO(base64.b64decode(image_data)))

    # Prepara gli input per il modello utilizzando il processor
    inputs = processor(text=[text], images=[image], return_tensors="pt")  # Modificato qui

    # Esegui il modello
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            do_sample=False,
            use_cache=True,
            max_new_tokens=256,
            eos_token_id=processor.tokenizer.eos_token_id,  # Modificato qui
            pad_token_id=processor.tokenizer.pad_token_id  # Modificato qui
        )

    # Decodifica l'output
    prompt_len = inputs["input_ids"].shape[1]  # Aggiunto per il decoding corretto
    generated_text = processor.batch_decode(outputs[:, prompt_len:], skip_special_tokens=True)[0]  # Modificato qui

    # Restituisci il risultato
    return jsonify({'generated_text': generated_text})

if __name__ == '__main__':
    app.run(debug=True)