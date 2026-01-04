from flask import Flask, request, jsonify
import pickle
import numpy as np
from tensorflow.keras.models import load_model
from config import LR_MODEL_PATH, NN_MODEL_PATH, FEATURE_COLUMNS, LR_WEIGHT, NN_WEIGHT

app = Flask(__name__)

with open(LR_MODEL_PATH, "rb") as f:
    lr_model, scaler = pickle.load(f)

nn_model = load_model(NN_MODEL_PATH)

@app.route("/predict", methods=["POST"])
def predict_api():
    try:
        data = request.json
        X = np.array([[data[col] for col in FEATURE_COLUMNS]])
        X_scaled = scaler.transform(X)

        lr_prob = lr_model.predict_proba(X_scaled)[0][1]
        nn_prob = nn_model.predict(X_scaled)[0][0]

        final_prob = (LR_WEIGHT * lr_prob) + (NN_WEIGHT * nn_prob)

        return jsonify({
            "probability": round(float(final_prob), 2),
            "needs_intervention": int(final_prob >= 0.5)
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)
