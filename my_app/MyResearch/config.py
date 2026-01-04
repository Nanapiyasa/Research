
import os

# Centralized configuration class for dataset, model, and encoder paths
class Config:

    BASE_DIR = os.getcwd()
    
    DATASET_FILENAME = "dataset/Dataset.csv"
    MODEL_FILENAME = "model/ds_level_rf_model.pkl"
    ENCODER_FILENAME = "model/ds_level_encoder.pkl"
    
    DATASET_PATH = os.path.join(BASE_DIR, DATASET_FILENAME)
    MODEL_PATH = os.path.join(BASE_DIR, MODEL_FILENAME)
    ENCODER_PATH = os.path.join(BASE_DIR, ENCODER_FILENAME)
    
    # Random seed for reproducibility
    RANDOM_SEED = 42

    # Model hyperparameters
    RF_N_ESTIMATORS = 200
    RF_MAX_DEPTH = 8
