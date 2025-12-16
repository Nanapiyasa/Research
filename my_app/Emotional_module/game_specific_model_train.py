"""
Game-Specific ML Model Trainer
Trains models specifically on game interaction features
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, f1_score
import joblib
import json
from datetime import datetime
from typing import Dict, Tuple

class GameModelTrainer:
    """
    Train ML models using game interaction features
    """
    
    def __init__(self, model_type: str = 'random_forest'):
        self.model_type = model_type
        self.model = None
        self.scaler = StandardScaler()
        self.feature_names = []
        self.training_history = []
        
    def prepare_data(self, df: pd.DataFrame, target_col: str = 'down_syndrome_level'):
        """
        Prepare data for training
        """
        # Remove non-feature columns
        exclude_cols = ['user_id', 'session_id', target_col, 'completed']
        feature_cols = [col for col in df.columns if col not in exclude_cols]
        
        X = df[feature_cols]
        y = df[target_col]
        
        # Handle missing values
        X = X.fillna(X.mean())
        
        self.feature_names = feature_cols
        
        print(f"Prepared {len(X)} samples with {len(feature_cols)} features")
        print(f"Target distribution:\n{y.value_counts()}")
        
        return X, y
    
    def create_model(self, **kwargs):
        """
        Create model based on type
        """
        if self.model_type == 'random_forest':
            self.model = RandomForestClassifier(
                n_estimators=kwargs.get('n_estimators', 150),
                max_depth=kwargs.get('max_depth', 12),
                min_samples_split=kwargs.get('min_samples_split', 4),
                min_samples_leaf=kwargs.get('min_samples_leaf', 2),
                random_state=42,
                class_weight='balanced',
                n_jobs=-1
            )
        elif self.model_type == 'gradient_boosting':
            self.model = GradientBoostingClassifier(
                n_estimators=kwargs.get('n_estimators', 100),
                learning_rate=kwargs.get('learning_rate', 0.1),
                max_depth=kwargs.get('max_depth', 5),
                random_state=42
            )
        elif self.model_type == 'neural_network':
            self.model = MLPClassifier(
                hidden_layer_sizes=kwargs.get('hidden_layers', (128, 64, 32)),
                activation='relu',
                solver='adam',
                max_iter=kwargs.get('max_iter', 500),
                random_state=42,
                early_stopping=True
            )
        else:
            raise ValueError(f"Unknown model type: {self.model_type}")
        
        print(f"Created {self.model_type} model")
        return self.model
    
    def train(self, X: pd.DataFrame, y: pd.Series, 
             test_size: float = 0.2, 
             validate: bool = True) -> Dict:
        """
        Train the model
        """
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=42, stratify=y
        )
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Create model if not exists
        if self.model is None:
            self.create_model()
        
        print(f"\nTraining {self.model_type} model...")
        print(f"Training set: {len(X_train)} samples")
        print(f"Test set: {len(X_test)} samples")
        
        # Train
        self.model.fit(X_train_scaled, y_train)
        
        # Evaluate
        train_pred = self.model.predict(X_train_scaled)
        test_pred = self.model.predict(X_test_scaled)
        
        train_accuracy = accuracy_score(y_train, train_pred)
        test_accuracy = accuracy_score(y_test, test_pred)
        
        print(f"\n=== Model Performance ===")
        print(f"Training Accuracy: {train_accuracy:.4f}")
        print(f"Test Accuracy: {test_accuracy:.4f}")
        
        # Cross-validation
        if validate:
            cv_scores = cross_val_score(self.model, X_train_scaled, y_train, 
                                       cv=5, scoring='accuracy')
            print(f"Cross-validation Accuracy: {cv_scores.mean():.4f} (+/- {cv_scores.std():.4f})")
        
        print("\n=== Classification Report (Test Set) ===")
        print(classification_report(y_test, test_pred))
        
        print("\n=== Confusion Matrix ===")
        print(confusion_matrix(y_test, test_pred))
        
        # Feature importance
        feature_importance = self._get_feature_importance()
        
        # Store training history
        training_record = {
            'timestamp': datetime.now().isoformat(),
            'model_type': self.model_type,
            'train_accuracy': float(train_accuracy),
            'test_accuracy': float(test_accuracy),
            'cv_accuracy': float(cv_scores.mean()) if validate else None,
            'n_features': len(self.feature_names),
            'n_samples': len(X)
        }
        self.training_history.append(training_record)
        
        return {
            'train_accuracy': train_accuracy,
            'test_accuracy': test_accuracy,
            'cv_accuracy': cv_scores.mean() if validate else None,
            'feature_importance': feature_importance,
            'predictions': {
                'y_test': y_test.tolist(),
                'y_pred': test_pred.tolist()
            }
        }
    
    def hyperparameter_tuning(self, X: pd.DataFrame, y: pd.Series) -> Dict:
        """
        Perform hyperparameter tuning using GridSearchCV
        """
        print("\nPerforming hyperparameter tuning...")
        
        # Scale features
        X_scaled = self.scaler.fit_transform(X)
        
        # Define parameter grid based on model type
        if self.model_type == 'random_forest':
            param_grid = {
                'n_estimators': [100, 150, 200],
                'max_depth': [10, 12, 15],
                'min_samples_split': [2, 4, 6],
                'min_samples_leaf': [1, 2, 3]
            }
        elif self.model_type == 'gradient_boosting':
            param_grid = {
                'n_estimators': [50, 100, 150],
                'learning_rate': [0.01, 0.1, 0.2],
                'max_depth': [3, 5, 7]
            }
        elif self.model_type == 'neural_network':
            param_grid = {
                'hidden_layer_sizes': [(64, 32), (128, 64, 32), (256, 128, 64)],
                'learning_rate_init': [0.001, 0.01]
            }
        else:
            raise ValueError(f"No param grid defined for {self.model_type}")
        
        # Create base model
        self.create_model()
        
        # Grid search
        grid_search = GridSearchCV(
            self.model, param_grid, 
            cv=5, scoring='accuracy', 
            n_jobs=-1, verbose=1
        )
        
        grid_search.fit(X_scaled, y)
        
        print(f"\nBest parameters: {grid_search.best_params_}")
        print(f"Best cross-validation score: {grid_search.best_score_:.4f}")
        
        # Update model with best parameters
        self.model = grid_search.best_estimator_
        
        return {
            'best_params': grid_search.best_params_,
            'best_score': float(grid_search.best_score_),
            'all_results': grid_search.cv_results_
        }
    
    def _get_feature_importance(self) -> Dict:
        """
        Get feature importance from trained model
        """
        if self.model is None:
            return {}
        
        importance_dict = {}
        
        if hasattr(self.model, 'feature_importances_'):
            # Tree-based models
            importances = self.model.feature_importances_
            for feature, importance in zip(self.feature_names, importances):
                importance_dict[feature] = float(importance)
        elif hasattr(self.model, 'coefs_'):
            # Neural network - use average absolute weight
            weights = np.abs(self.model.coefs_[0]).mean(axis=1)
            for feature, weight in zip(self.feature_names, weights):
                importance_dict[feature] = float(weight)
        
        # Sort by importance
        importance_dict = dict(sorted(importance_dict.items(), 
                                    key=lambda x: x[1], 
                                    reverse=True))
        
        print("\n=== Top 10 Most Important Features ===")
        for i, (feature, importance) in enumerate(list(importance_dict.items())[:10], 1):
            print(f"{i}. {feature}: {importance:.4f}")
        
        return importance_dict
    
    def predict_with_confidence(self, X: pd.DataFrame) -> pd.DataFrame:
        """
        Make predictions with confidence scores
        """
        if self.model is None:
            raise ValueError("Model not trained. Call train() first.")
        
        X_scaled = self.scaler.transform(X)
        
        predictions = self.model.predict(X_scaled)
        probabilities = self.model.predict_proba(X_scaled)
        
        # Get confidence (max probability)
        confidence = probabilities.max(axis=1)
        
        results = pd.DataFrame({
            'prediction': predictions,
            'confidence': confidence
        })
        
        # Add probability for each class
        for i in range(probabilities.shape[1]):
            results[f'prob_class_{i}'] = probabilities[:, i]
        
        return results
    
    def save_model(self, filepath: str = 'models/game_model.pkl'):
        """
        Save trained model
        """
        model_package = {
            'model': self.model,
            'scaler': self.scaler,
            'model_type': self.model_type,
            'feature_names': self.feature_names,
            'training_history': self.training_history,
            'trained_at': datetime.now().isoformat()
        }
        
        joblib.dump(model_package, filepath)
        print(f"\nModel saved to {filepath}")
        
        # Save metadata
        metadata = {
            'model_type': self.model_type,
            'n_features': len(self.feature_names),
            'feature_names': self.feature_names,
            'training_history': self.training_history
        }
        
        metadata_path = filepath.replace('.pkl', '_metadata.json')
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"Metadata saved to {metadata_path}")
    
    def load_model(self, filepath: str = 'models/game_model.pkl'):
        """
        Load trained model
        """
        model_package = joblib.load(filepath)
        
        self.model = model_package['model']
        self.scaler = model_package['scaler']
        self.model_type = model_package['model_type']
        self.feature_names = model_package['feature_names']
        self.training_history = model_package.get('training_history', [])
        
        print(f"Model loaded from {filepath}")
        print(f"Model type: {self.model_type}")
        print(f"Features: {len(self.feature_names)}")


class ModelEnsemble:
    """
    Ensemble multiple models for better prediction
    """
    
    def __init__(self):
        self.models = []
        self.weights = []
    
    def add_model(self, model: GameModelTrainer, weight: float = 1.0):
        """
        Add a model to the ensemble
        """
        self.models.append(model)
        self.weights.append(weight)
        print(f"Added {model.model_type} with weight {weight}")
    
    def predict(self, X: pd.DataFrame) -> np.ndarray:
        """
        Make ensemble predictions
        """
        if not self.models:
            raise ValueError("No models in ensemble")
        
        # Collect predictions from all models
        all_probas = []
        for model in self.models:
            X_scaled = model.scaler.transform(X)
            probas = model.model.predict_proba(X_scaled)
            all_probas.append(probas)
        
        # Weighted average
        ensemble_probas = np.average(all_probas, axis=0, 
                                     weights=self.weights)
        
        # Get final predictions
        predictions = ensemble_probas.argmax(axis=1)
        
        return predictions


# Example usage
if __name__ == "__main__":
    # Create sample data (replace with actual game data)
    np.random.seed(42)
    
    df = pd.DataFrame({
        'user_id': np.repeat(range(100), 5),
        'avg_reaction_time': np.random.uniform(0.5, 3.0, 500),
        'accuracy_rate': np.random.uniform(0.4, 1.0, 500),
        'move_efficiency': np.random.uniform(0.5, 1.0, 500),
        'learning_rate': np.random.uniform(-0.2, 0.3, 500),
        'cognitive_efficiency': np.random.uniform(10, 50, 500),
        'down_syndrome_level': np.random.randint(0, 4, 500)
    })
    
    # Train Random Forest
    rf_trainer = GameModelTrainer(model_type='random_forest')
    X, y = rf_trainer.prepare_data(df)
    rf_results = rf_trainer.train(X, y)
    
    # Hyperparameter tuning
    tuning_results = rf_trainer.hyperparameter_tuning(X, y)
    
    # Save model
    rf_trainer.save_model('models/game_rf_model.pkl')
    
    print("\n=== Training Complete ===")
    print(f"Final test accuracy: {rf_results['test_accuracy']:.4f}")