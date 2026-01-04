import os
import pandas as pd
import joblib
from utils import scale_features


# Paths to saved models
MODELS_DIR = "Models"
CLASSIFIER_PATH = os.path.join(MODELS_DIR, "sel_classifier.pkl")
SCALER_PATH = os.path.join(MODELS_DIR, "scaler.pkl")
ENCODER_PATH = os.path.join(MODELS_DIR, "label_encoder.pkl")


# Prediction function

def predict_new_players(new_players_data):

    # Load model, scaler, encoder
    clf = joblib.load(CLASSIFIER_PATH)
    scaler = joblib.load(SCALER_PATH)
    le = joblib.load(ENCODER_PATH)

    # Convert to DataFrame
    new_players = pd.DataFrame(new_players_data, columns=[
        "_score", "timePerScenario", "attemptsPerScenario", "correctAnswers", "completionStatus"
    ])

    # Scale features
    X_scaled = scale_features(new_players, scaler)

    # Predict
    y_pred_encoded = clf.predict(X_scaled)
    y_pred = le.inverse_transform(y_pred_encoded)
    return y_pred


#  usage
if __name__ == "__main__":
    new_players_data = [[50, 12, 1, 5, 100]]
    predictions = predict_new_players(new_players_data)
    for i, pred in enumerate(predictions):
        print(f"Player {i+1} predicted SEL Level: {pred}")
