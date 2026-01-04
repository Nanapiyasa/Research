# data_loader.py
import pandas as pd

def load_dataset(csv_path="Dataset/SEL_game_dataset.csv"):
    try:
        df = pd.read_csv(csv_path)
        return df
    except FileNotFoundError:
        raise FileNotFoundError(f"{csv_path} not found!")
