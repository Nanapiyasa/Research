"""
ML Model Training Pipeline for Down Syndrome Level Prediction
Trains model using sensor data (Heart Rate, SpO2) and cognitive game metrics
"""

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import joblib
import json
from datetime import datetime

class DownSyndromePredictor:
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.feature_names = [
            'heart_rate_mean', 'heart_rate_std', 'heart_rate_min', 'heart_rate_max',
            'spo2_mean', 'spo2_std', 'spo2_min', 'spo2_max',
            'game_score', 'game_time', 'mistakes_count', 'reaction_time'
        ]
        
    def preprocess_data(self, df):
        """
        Preprocess raw sensor and game data
        """
        # Aggregate sensor data (assuming time-series data)
        features = pd.DataFrame()
        
        # Heart rate features
        features['heart_rate_mean'] = df.groupby('user_id')['heart_rate'].mean()
        features['heart_rate_std'] = df.groupby('user_id')['heart_rate'].std()
        features['heart_rate_min'] = df.groupby('user_id')['heart_rate'].min()
        features['heart_rate_max'] = df.groupby('user_id')['heart_rate'].max()
        
        # SpO2 features
        features['spo2_mean'] = df.groupby('user_id')['spo2'].mean()
        features['spo2_std'] = df.groupby('user_id')['spo2'].std()
        features['spo2_min'] = df.groupby('user_id')['spo2'].min()
        features['spo2_max'] = df.groupby('user_id')['spo2'].max()
        
        # Game performance features
        features['game_score'] = df.groupby('user_id')['game_score'].mean()
        features['game_time'] = df.groupby('user_id')['game_time'].mean()
        features['mistakes_count'] = df.groupby('user_id')['mistakes_count'].sum()
        features['reaction_time'] = df.groupby('user_id')['reaction_time'].mean()
        
        # Target variable
        labels = df.groupby('user_id')['down_syndrome_level'].first()
        
        return features, labels
    
    def train(self, X, y, test_size=0.2, random_state=42):
        """
        Train Random Forest classifier
        """
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=random_state, stratify=y
        )
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train model
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=random_state,
            class_weight='balanced'
        )
        
        print("Training model...")
        self.model.fit(X_train_scaled, y_train)
        
        # Evaluate
        y_pred = self.model.predict(X_test_scaled)

        
        
        print("\n=== Model Performance ===")
        print(f"Accuracy: {accuracy_score(y_test, y_pred):.4f}")
        print("\nClassification Report:")
        print(classification_report(y_test, y_pred))
        print("\nConfusion Matrix:")
        print(confusion_matrix(y_test, y_pred))
        
        # Feature importance
        feature_importance = pd.DataFrame({
            'feature': self.feature_names,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        print("\n=== Feature Importance ===")
        print(feature_importance)
        
        return {
            'accuracy': accuracy_score(y_test, y_pred),
            'feature_importance': feature_importance.to_dict('records')
        }
    
    def save_model(self, model_path='models/down_syndrome_predictor.pkl'):
        """
        Save trained model and scaler
        """
        model_data = {
            'model': self.model,
            'scaler': self.scaler,
            'feature_names': self.feature_names,
            'trained_at': datetime.now().isoformat()
        }
        joblib.dump(model_data, model_path)
        print(f"Model saved to {model_path}")
    
    def load_model(self, model_path='models/down_syndrome_predictor.pkl'):
        """
        Load trained model
        """
        model_data = joblib.load(model_path)
        self.model = model_data['model']
        self.scaler = model_data['scaler']
        self.feature_names = model_data['feature_names']
        print(f"Model loaded from {model_path}")
    
    def predict(self, features):
        """
        Predict Down Syndrome level for new data
        """
        if self.model is None:
            raise ValueError("Model not trained. Call train() first.")
        
        features_scaled = self.scaler.transform(features)
        prediction = self.model.predict(features_scaled)
        probabilities = self.model.predict_proba(features_scaled)
        
        return {
            'prediction': int(prediction[0]),
            'probabilities': probabilities[0].tolist()
        }


# Example usage and training script
if __name__ == "__main__":
    # Load your dataset (replace with actual data loading)
    # Expected columns: user_id, heart_rate, spo2, game_score, game_time, 
    #                   mistakes_count, reaction_time, down_syndrome_level
    
    print("Loading dataset...")
    # df = pd.read_csv('data/sensor_game_data.csv')
    
    # # For demonstration, create sample data
    # np.random.seed(42)
    # n_samples = 1000
    
    df = pd.DataFrame({
        'user_id': np.repeat(range(100), 10),
        'heart_rate': np.random.normal(75, 15, n_samples),
        'spo2': np.random.normal(96, 2, n_samples),
        'game_score': np.random.randint(0, 100, n_samples),
        'game_time': np.random.uniform(30, 180, n_samples),
        'mistakes_count': np.random.randint(0, 20, n_samples),
        'reaction_time': np.random.uniform(0.5, 3.0, n_samples),
        'down_syndrome_level': np.repeat(np.random.randint(0, 4, 100), 10)
    })
    
    # Initialize predictor
    predictor = DownSyndromePredictor()
    
    # Preprocess data
    print("\nPreprocessing data...")
    X, y = predictor.preprocess_data(df)
    
    # Train model
    metrics = predictor.train(X, y)
    
    # Save model
    predictor.save_model()
    
    # Test prediction
    print("\n=== Testing Prediction ===")
    sample_features = X.iloc[[0]]
    result = predictor.predict(sample_features)
    print(f"Prediction: Level {result['prediction']}")
    print(f"Probabilities: {result['probabilities']}")