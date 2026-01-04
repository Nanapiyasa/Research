import pickle
import numpy as np
import pandas as pd
from tensorflow.keras.models import load_model
from dataload import load_dataset
from config import (
    LR_MODEL_PATH, NN_MODEL_PATH,
    FEATURE_COLUMNS, LR_WEIGHT, NN_WEIGHT,
    PREDICTION_OUTPUT
)

def predict():
    with open(LR_MODEL_PATH, "rb") as f:
        lr_model, scaler = pickle.load(f)

    nn_model = load_model(NN_MODEL_PATH)
    df = load_dataset()

    # user inputs
    input_data = pd.DataFrame({
        "time_sec": [20],
        "number_of_times_played": [1],
        "score": [100],
        "difficulty_level_encoded": [2]
    })

    X_scaled = scaler.transform(input_data)

    lr_prob = lr_model.predict_proba(X_scaled)[0][1]
    nn_prob = nn_model.predict(X_scaled)[0][0]

    final_prob = (LR_WEIGHT * lr_prob) + (NN_WEIGHT * nn_prob)

    df["distance"] = np.linalg.norm(
        df[FEATURE_COLUMNS].values - input_data.values,
        axis=1
    )
    recommendation = df.loc[df["distance"].idxmin(), "recommendation"]

    output = pd.DataFrame({
        "recommendation": [recommendation],
        "probability": [round(final_prob, 2)]
    })

    output.to_csv(PREDICTION_OUTPUT, index=False)

    print("--> Recommendation:", recommendation)
    print("-->  Probability:", round(final_prob, 2))

if __name__ == "__main__":
    predict()
