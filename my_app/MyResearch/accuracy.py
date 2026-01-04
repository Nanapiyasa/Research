from sklearn.metrics import accuracy_score, classification_report

def print_accuracy(y_train, y_train_pred, y_test, y_test_pred, classes):
    train_acc = accuracy_score(y_train, y_train_pred)
    test_acc = accuracy_score(y_test, y_test_pred)
    print(f"\n-- Training Accuracy: {train_acc:.4f}")
    print(f"-- Testing Accuracy: {test_acc:.4f}\n")

    print("-- Classification Report (Test Data):")
    print(classification_report(y_test, y_test_pred, target_names=classes, zero_division=0))
