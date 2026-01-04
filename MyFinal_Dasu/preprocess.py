from sklearn.preprocessing import StandardScaler
from config import FEATURE_COLUMNS, TARGET_COLUMN, TARGET_MAP

def preprocess_data(df):
    X = df[FEATURE_COLUMNS]
    y = df[TARGET_COLUMN].map(TARGET_MAP)

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    return X_scaled, y, scaler
