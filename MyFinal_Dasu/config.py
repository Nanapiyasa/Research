import os
import warnings
warnings.filterwarnings('ignore')
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

DATASET_PATH = os.path.join(BASE_DIR, "Dataset/lifestyle_dataset.csv")
LR_MODEL_PATH = os.path.join(BASE_DIR, "Models/lr_model.pkl")
NN_MODEL_PATH = os.path.join(BASE_DIR, "Models/nn_model.h5")
PREDICTION_OUTPUT = os.path.join(BASE_DIR, "predicted_lifestyle.csv")

FEATURE_COLUMNS = [
    "time_sec",
    "number_of_times_played",
    "score",
    "difficulty_level_encoded"
]

TARGET_COLUMN = "needs_intervention"
TARGET_MAP = {"Yes": 1, "No": 0}

TEST_SIZE = 0.2
RANDOM_STATE = 42
MAX_ITER = 500

# Logistic Regression tuning
CV_FOLDS = 5
PARAM_GRID = {
    "C": [0.01, 0.1, 1, 10],
    "solver": ["lbfgs"],
    "penalty": ["l2"],
    "class_weight": [None, "balanced"]
}

# Neural Network
NN_EPOCHS = 100
NN_BATCH_SIZE = 16
NN_LR = 0.001

# Hybrid weights
LR_WEIGHT = 0.4
NN_WEIGHT = 0.6
