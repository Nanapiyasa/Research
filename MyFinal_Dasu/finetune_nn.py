from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping
from config import NN_EPOCHS, NN_BATCH_SIZE, NN_LR

def train_nn(X_train, y_train, input_dim):
    model = Sequential([
        Dense(64, activation="relu", input_shape=(input_dim,)),
        Dropout(0.3),
        Dense(32, activation="relu"),
        Dropout(0.2),
        Dense(1, activation="sigmoid")
    ])

    model.compile(
        optimizer=Adam(learning_rate=NN_LR),
        loss="binary_crossentropy",
        metrics=["accuracy"]
    )

    early_stop = EarlyStopping(patience=10, restore_best_weights=True)

    model.fit(
        X_train,
        y_train,
        epochs=NN_EPOCHS,
        batch_size=NN_BATCH_SIZE,
        validation_split=0.2,
        callbacks=[early_stop],
        verbose=0
    )

    return model
