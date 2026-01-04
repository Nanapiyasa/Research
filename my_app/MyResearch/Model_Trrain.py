import pandas as pd
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, StratifiedKFold, GridSearchCV
import joblib
from imblearn.over_sampling import SMOTE

from config import Config
from data_loader import load_dataset, get_features_labels
from graphs import plot_confusion_matrix, plot_feature_importance, plot_actual_vs_predicted
from accuracy import print_accuracy

def train_model():
    # Load dataset
    df = load_dataset()
    X, y = get_features_labels(df)

    # Encode labels
    encoder = LabelEncoder()
    y_encoded = encoder.fit_transform(y)

    # Handle class imbalance
    sm = SMOTE(random_state=Config.RANDOM_SEED)
    X_res, y_res = sm.fit_resample(X, y_encoded)
    print(f"-- Dataset balanced: {X_res.shape[0]} samples after SMOTE")

    # Train-test split
    X_train, X_test, y_train, y_test = train_test_split(
        X_res, y_res, test_size=0.2, random_state=Config.RANDOM_SEED, stratify=y_res
    )

    # Hyperparameter tuning
    param_grid = {
        "n_estimators": [200, 300, 400],
        "max_depth": [6, 8, 10, None],
        "min_samples_split": [2, 4, 6],
        "min_samples_leaf": [1, 2, 4],
        "max_features": ["sqrt", "log2", None]
    }

    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=Config.RANDOM_SEED)
    grid = GridSearchCV(
        estimator=RandomForestClassifier(random_state=Config.RANDOM_SEED, class_weight="balanced"),
        param_grid=param_grid,
        scoring="accuracy",
        cv=cv,
        n_jobs=-1,
        verbose=1
    )
    grid.fit(X_train, y_train)
    best_rf = grid.best_estimator_
    print(f"\n-- Best RandomForest Hyperparameters: {grid.best_params_}")

    # Predictions
    y_train_pred = best_rf.predict(X_train)
    y_test_pred = best_rf.predict(X_test)

    # Accuracy metrics
    print_accuracy(y_train, y_train_pred, y_test, y_test_pred, encoder.classes_)

    # Graphs
    plot_confusion_matrix(y_test, y_test_pred, encoder.classes_, title="Confusion Matrix (Test Data)")
    plot_feature_importance(best_rf, X.columns)
    plot_actual_vs_predicted(y_test, y_test_pred, encoder.inverse_transform(y_encoded))

    # Save model and encoder
    joblib.dump(best_rf, Config.MODEL_PATH)
    joblib.dump(encoder, Config.ENCODER_PATH)
    print("-- Model and encoder saved successfully.")


if __name__ == "__main__":
    train_model()
