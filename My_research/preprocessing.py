# preprocessing.py
from sklearn.preprocessing import StandardScaler, LabelEncoder

def preprocess_features(df):
    X = df[["_score", "timePerScenario", "attemptsPerScenario", "correctAnswers", "completionStatus"]]
    y = df["Label"]

    # Encode labels
    le = LabelEncoder()
    y_encoded = le.fit_transform(y)

    # Scale features
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    return X_scaled, y_encoded, scaler, le
