import pandas as pd
from path_utils import check_path_exists
from config import Config

# Loads the dataset CSV into a Pandas
def load_dataset() -> pd.DataFrame:

    check_path_exists(Config.DATASET_PATH, "Dataset")
    
    try:
        df = pd.read_csv(Config.DATASET_PATH)
        print(f"-- Dataset loaded successfully with {len(df)} rows.")
        return df
    except Exception as e:
        print(f"-- Failed to load dataset: {e}")
        raise

# Splits DataFrame
def get_features_labels(df: pd.DataFrame):

    feature_cols = ["Age", "Weight", "Height", "Memory_Score", "Reaction_Time", "Heart_Rate"]
    target_col = "Down_Syndrome_Level"
    
    X = df[feature_cols]
    y = df[target_col]
    
    return X, y
