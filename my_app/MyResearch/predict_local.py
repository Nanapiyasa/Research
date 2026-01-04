import pandas as pd
from data_loader import load_dataset
from model_utils import load_model_and_encoder

def predict_hardcoded_sample():

    #  input
    sample_input = {
        "Age": 8,
        "Weight": 40,
        "Height": 52,
        "Memory_Score": 20,
        "Reaction_Time": 80,
        "Heart_Rate": 250
    }

    print("\n--- User Input ---")
    for k, v in sample_input.items():
        print(f"{k}: {v}")


    # Prepare input for model

    features = ["Age", "Weight", "Height", "Memory_Score", "Reaction_Time", "Heart_Rate"]
    X_sample = pd.DataFrame([sample_input])[features]


    # Load model and encoder
    model, encoder = load_model_and_encoder()


    # Predict
    pred_encoded = model.predict(X_sample)
    predicted_level = encoder.inverse_transform(pred_encoded)[0]
    df = load_dataset()

    matching_row = df[
        (df["Age"] == sample_input["Age"]) &
        (df["Weight"] == sample_input["Weight"]) &
        (df["Height"] == sample_input["Height"])
    ]

    if not matching_row.empty:
        recommendation = matching_row.iloc[0]["Recommendation"]
    else:

        recommendation_rows = df[df["Down_Syndrome_Level"] == predicted_level]
        recommendation = recommendation_rows.sample(1).iloc[0]["Recommendation"]

    # ----------------------------
    # Output
    # ----------------------------
    print(f"\nPredicted Down Syndrome Level: {predicted_level}")
    print(f"Recommendation: {recommendation}\n")

if __name__ == "__main__":
    predict_hardcoded_sample()
