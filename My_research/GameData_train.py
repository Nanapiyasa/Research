import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report

from data_loader import load_dataset
from preprocessing import preprocess_features

def train_model():
    # Load dataset
    df = load_dataset()

    # Preprocess
    X_scaled, y_encoded, scaler, le = preprocess_features(df)

    # Split train/test
    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded
    )

    # Train Random Forest
    clf = RandomForestClassifier(n_estimators=200, random_state=42)
    clf.fit(X_train, y_train)

    # Evaluate
    y_pred = clf.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    print(f"Test Accuracy: {acc*100:.2f}%")
    print("Confusion Matrix:\n", confusion_matrix(y_test, y_pred))
    print("\nClassification Report:\n", classification_report(y_test, y_pred, target_names=le.classes_))

    # Save model, scaler, and label encoder
    joblib.dump(clf, "Models/sel_classifier.pkl")
    joblib.dump(scaler, "Models/scaler.pkl")
    joblib.dump(le, "Models/label_encoder.pkl")
    print("Model, scaler, and label encoder saved!")

if __name__ == "__main__":
    train_model()
