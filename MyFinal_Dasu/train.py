import pickle
import numpy as np
import matplotlib.pyplot as plt

from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, roc_curve, auc

from dataload import load_dataset
from preprocess import preprocess_data
from finetune_lr import tune_lr
from finetune_nn import train_nn

from config import (
    TEST_SIZE, RANDOM_STATE,
    LR_MODEL_PATH, NN_MODEL_PATH,
    LR_WEIGHT, NN_WEIGHT
)


def train():

    # Load & preprocess data
    df = load_dataset()
    X, y, scaler = preprocess_data(df)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y,
        test_size=TEST_SIZE,
        random_state=RANDOM_STATE,
        stratify=y
    )


    # Train models
    print("🔹 Training Logistic Regression...")
    lr_model = tune_lr(X_train, y_train)

    print("🔹 Training Neural Network...")
    nn_model = train_nn(X_train, y_train, X_train.shape[1])


    # Predictions
    lr_prob = lr_model.predict_proba(X_test)[:, 1]
    nn_prob = nn_model.predict(X_test).flatten()
    hybrid_prob = (LR_WEIGHT * lr_prob) + (NN_WEIGHT * nn_prob)

    lr_pred = (lr_prob >= 0.5).astype(int)
    nn_pred = (nn_prob >= 0.5).astype(int)
    hybrid_pred = (hybrid_prob >= 0.5).astype(int)


    # Accuracy Comparison Table
    print("\n-->  Accuracy")
    print("------------------------------------------------")
    print(f"Hybrid Model    Accuracy    : {accuracy_score(y_test, hybrid_pred):.3f}")


    # ROC–AUC Visualization-
    fpr_lr, tpr_lr, _ = roc_curve(y_test, lr_prob)
    fpr_nn, tpr_nn, _ = roc_curve(y_test, nn_prob)
    fpr_hy, tpr_hy, _ = roc_curve(y_test, hybrid_prob)

    plt.figure()
    plt.plot(fpr_lr, tpr_lr, label=f"LR (AUC={auc(fpr_lr, tpr_lr):.2f})")
    plt.plot(fpr_nn, tpr_nn, label=f"NN (AUC={auc(fpr_nn, tpr_nn):.2f})")
    plt.plot(fpr_hy, tpr_hy, label=f"Hybrid (AUC={auc(fpr_hy, tpr_hy):.2f})")
    plt.plot([0, 1], [0, 1], linestyle="--")

    plt.xlabel("False Positive Rate")
    plt.ylabel("True Positive Rate")
    plt.title("ROC–AUC Comparison (During Training)")
    plt.legend()
    plt.show()


    # Save models
    with open(LR_MODEL_PATH, "wb") as f:
        pickle.dump((lr_model, scaler), f)

    nn_model.save(NN_MODEL_PATH)

    print("\n Models trained, evaluated, and saved successfully")


if __name__ == "__main__":
    train()
