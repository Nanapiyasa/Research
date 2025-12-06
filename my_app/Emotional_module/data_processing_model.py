"""
Data Preprocessing Module
Handles cleaning, validation, and feature engineering for sensor and game data
"""

import pandas as pd
import numpy as np
from datetime import datetime
import json

class DataPreprocessor:
    def __init__(self):
        self.valid_ranges = {
            'heart_rate': (40, 200),
            'spo2': (70, 100),
            'game_score': (0, 100),
            'game_time': (0, 600),
            'reaction_time': (0, 10)
        }
    
    def validate_sensor_data(self, df):
        """
        Validate sensor readings and remove outliers
        """
        print("Validating sensor data...")
        original_count = len(df)
        
        # Remove invalid heart rate readings
        df = df[
            (df['heart_rate'] >= self.valid_ranges['heart_rate'][0]) &
            (df['heart_rate'] <= self.valid_ranges['heart_rate'][1])
        ]
        
        # Remove invalid SpO2 readings
        df = df[
            (df['spo2'] >= self.valid_ranges['spo2'][0]) &
            (df['spo2'] <= self.valid_ranges['spo2'][1])
        ]
        
        removed = original_count - len(df)
        print(f"Removed {removed} invalid sensor readings ({removed/original_count*100:.2f}%)")
        
        return df
    
    def handle_missing_values(self, df):
        """
        Handle missing values using appropriate strategies
        """
        print("\nHandling missing values...")
        
        # Forward fill for time-series sensor data
        sensor_cols = ['heart_rate', 'spo2']
        df[sensor_cols] = df.groupby('user_id')[sensor_cols].fillna(method='ffill')
        
        # Backward fill remaining
        df[sensor_cols] = df.groupby('user_id')[sensor_cols].fillna(method='bfill')
        
        # Fill game data with median
        game_cols = ['game_score', 'game_time', 'mistakes_count', 'reaction_time']
        for col in game_cols:
            if col in df.columns:
                df[col].fillna(df[col].median(), inplace=True)
        
        print(f"Missing values handled. Remaining nulls: {df.isnull().sum().sum()}")
        
        return df
    
    def engineer_features(self, df):
        """
        Create additional features from raw data
        """
        print("\nEngineering features...")
        
        # Heart rate variability (if timestamps available)
        if 'timestamp' in df.columns:
            df['hr_variability'] = df.groupby('user_id')['heart_rate'].transform(
                lambda x: x.rolling(window=5, min_periods=1).std()
            )
        
        # Performance ratio
        if 'game_score' in df.columns and 'game_time' in df.columns:
            df['performance_ratio'] = df['game_score'] / (df['game_time'] + 1)
        
        # Accuracy rate
        if 'game_score' in df.columns and 'mistakes_count' in df.columns:
            df['accuracy_rate'] = df['game_score'] / (df['mistakes_count'] + 1)
        
        # Stress indicator (simplified)
        if 'heart_rate' in df.columns:
            df['stress_indicator'] = (df['heart_rate'] - 60) / 40
            df['stress_indicator'] = df['stress_indicator'].clip(0, 1)
        
        print(f"Feature engineering complete. Total features: {len(df.columns)}")
        
        return df
    
    def normalize_timestamps(self, df):
        """
        Normalize and validate timestamps
        """
        if 'timestamp' not in df.columns:
            return df
        
        print("\nNormalizing timestamps...")
        
        # Convert to datetime
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        
        # Sort by user and timestamp
        df = df.sort_values(['user_id', 'timestamp'])
        
        # Calculate time deltas
        df['time_delta'] = df.groupby('user_id')['timestamp'].diff().dt.total_seconds()
        
        return df
    
    def aggregate_session_data(self, df, session_duration='5min'):
        """
        Aggregate data into sessions for analysis
        """
        print(f"\nAggregating data into {session_duration} sessions...")
        
        if 'timestamp' not in df.columns:
            print("Warning: No timestamp column found. Skipping aggregation.")
            return df
        
        # Set timestamp as index
        df = df.set_index('timestamp')
        
        # Aggregate by user and time window
        agg_dict = {
            'heart_rate': ['mean', 'std', 'min', 'max'],
            'spo2': ['mean', 'std', 'min', 'max']
        }
        
        if 'game_score' in df.columns:
            agg_dict['game_score'] = ['mean', 'max']
        if 'mistakes_count' in df.columns:
            agg_dict['mistakes_count'] = 'sum'
        if 'reaction_time' in df.columns:
            agg_dict['reaction_time'] = 'mean'
        
        aggregated = df.groupby([
            pd.Grouper(key='user_id'),
            pd.Grouper(freq=session_duration)
        ]).agg(agg_dict)
        
        # Flatten column names
        aggregated.columns = ['_'.join(col).strip() for col in aggregated.columns]
        aggregated = aggregated.reset_index()
        
        print(f"Aggregated to {len(aggregated)} session records")
        
        return aggregated
    
    def create_train_test_split(self, df, test_ratio=0.2):
        """
        Create temporal train-test split (important for time-series)
        """
        print(f"\nCreating train-test split ({test_ratio*100}% test)...")
        
        # Split by user to avoid data leakage
        unique_users = df['user_id'].unique()
        np.random.shuffle(unique_users)
        
        split_idx = int(len(unique_users) * (1 - test_ratio))
        train_users = unique_users[:split_idx]
        test_users = unique_users[split_idx:]
        
        train_df = df[df['user_id'].isin(train_users)]
        test_df = df[df['user_id'].isin(test_users)]
        
        print(f"Train set: {len(train_df)} records from {len(train_users)} users")
        print(f"Test set: {len(test_df)} records from {len(test_users)} users")
        
        return train_df, test_df
    
    def export_processed_data(self, df, output_path='data/processed_data.csv'):
        """
        Export processed data with metadata
        """
        df.to_csv(output_path, index=False)
        
        # Create metadata
        metadata = {
            'processed_at': datetime.now().isoformat(),
            'total_records': len(df),
            'unique_users': df['user_id'].nunique(),
            'features': list(df.columns),
            'data_shape': df.shape
        }
        
        metadata_path = output_path.replace('.csv', '_metadata.json')
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"\nData exported to {output_path}")
        print(f"Metadata saved to {metadata_path}")


# Example preprocessing pipeline
if __name__ == "__main__":
    # Load raw data
    print("Starting data preprocessing pipeline...\n")
    
    # Sample data generation (replace with actual data loading)
    np.random.seed(42)
    n_samples = 5000
    
    raw_data = pd.DataFrame({
        'user_id': np.random.randint(1, 101, n_samples),
        'timestamp': pd.date_range('2024-01-01', periods=n_samples, freq='30s'),
        'heart_rate': np.random.normal(75, 15, n_samples),
        'spo2': np.random.normal(96, 2, n_samples),
        'game_score': np.random.randint(0, 100, n_samples),
        'game_time': np.random.uniform(30, 180, n_samples),
        'mistakes_count': np.random.randint(0, 20, n_samples),
        'reaction_time': np.random.uniform(0.5, 3.0, n_samples),
        'down_syndrome_level': np.random.randint(0, 4, n_samples)
    })
    
    # Add some missing values and outliers for demonstration
    raw_data.loc[np.random.choice(raw_data.index, 100), 'heart_rate'] = np.nan
    raw_data.loc[np.random.choice(raw_data.index, 50), 'heart_rate'] = 250  # Outlier
    
    print(f"Raw data shape: {raw_data.shape}")
    print(f"Missing values: {raw_data.isnull().sum().sum()}")
    
    # Initialize preprocessor
    preprocessor = DataPreprocessor()
    
    # Run preprocessing pipeline
    data = preprocessor.validate_sensor_data(raw_data)
    data = preprocessor.handle_missing_values(data)
    data = preprocessor.normalize_timestamps(data)
    data = preprocessor.engineer_features(data)
    
    # Create train-test split
    train_data, test_data = preprocessor.create_train_test_split(data)
    
    # Export processed data
    preprocessor.export_processed_data(train_data, 'data/train_data.csv')
    preprocessor.export_processed_data(test_data, 'data/test_data.csv')
    
    print("\n=== Preprocessing Complete ===")
    print(f"Final data shape: {data.shape}")
    print(f"\nColumn summary:")
    print(data.describe())