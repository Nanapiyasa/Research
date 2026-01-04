import pandas as pd
from config import DATASET_PATH

def load_dataset():
    try:
        return pd.read_csv(DATASET_PATH)
    except FileNotFoundError:
        raise FileNotFoundError("Dataset file not found")
