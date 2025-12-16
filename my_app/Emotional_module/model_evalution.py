"""
Model Evaluation and Visualization
Comprehensive evaluation metrics and visualizations for trained models
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import (
    classification_report, confusion_matrix, accuracy_score,
    precision_recall_fscore_support, roc_curve, auc, 
    roc_auc_score
)
from sklearn.model_selection import learning_curve
import joblib
import json
from datetime import datetime

class ModelEvaluator:
    """
    Comprehensive model evaluation
    """
    
    def __init__(self, model_path='models/game_model.pkl'):
        self.model_package = joblib.load(model_path)
        self.model = self.model_package['model']
        self.scaler = self.model_package['scaler']
        self.feature_names = self.model_package['feature_names']
        
    def evaluate_on_test_set(self, X_test, y_test):
        """
        Comprehensive evaluation on test set
        """
        # Scale features
        X_test_scaled = self.scaler.transform(X_test)
        
        # Predictions
        y_pred = self.model.predict(X_test_scaled)
        y_prob = self.model.predict_proba(X_test_scaled)
        
        # Calculate metrics
        metrics = {
            'accuracy': accuracy_score(y_test, y_pred),
            'confusion_matrix': confusion_matrix(y_test, y_pred).tolist(),
            'classification_report': classification_report(y_test, y_pred, output_dict=True)
        }
        
        # Per-class metrics
        precision, recall, f1, support = precision_recall_fscore_support(
            y_test, y_pred, average=None
        )
        
        metrics['per_class'] = {
            'precision': precision.tolist(),
            'recall': recall.tolist(),
            'f1_score': f1.tolist(),
            'support': support.tolist()
        }
        
        # ROC AUC (for multiclass)
        try:
            metrics['roc_auc'] = roc_auc_score(y_test, y_prob, multi_class='ovr')
        except:
            metrics['roc_auc'] = None
        
        return metrics, y_pred, y_prob
    
    def plot_confusion_matrix(self, y_test, y_pred, save_path='evaluation/confusion_matrix.png'):
        """
        Plot confusion matrix
        """
        cm = confusion_matrix(y_test, y_pred)
        
        plt.figure(figsize=(10, 8))
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                   xticklabels=range(len(cm)),
                   yticklabels=range(len(cm)))
        plt.title('Confusion Matrix')
        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.tight_layout()
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"Confusion matrix saved to {save_path}")
    
    def plot_feature_importance(self, top_n=15, save_path='evaluation/feature_importance.png'):
        """
        Plot feature importance
        """
        if not hasattr(self.model, 'feature_importances_'):
            print("Model doesn't support feature importance")
            return
        
        importances = self.model.feature_importances_
        indices = np.argsort(importances)[::-1][:top_n]
        
        plt.figure(figsize=(12, 8))
        plt.title(f'Top {top_n} Most Important Features')
        plt.barh(range(top_n), importances[indices])
        plt.yticks(range(top_n), [self.feature_names[i] for i in indices])
        plt.xlabel('Feature Importance')
        plt.gca().invert_yaxis()
        plt.tight_layout()
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"Feature importance plot saved to {save_path}")
    
    def plot_roc_curves(self, X_test, y_test, save_path='evaluation/roc_curves.png'):
        """
        Plot ROC curves for each class
        """
        X_test_scaled = self.scaler.transform(X_test)
        y_prob = self.model.predict_proba(X_test_scaled)
        
        n_classes = y_prob.shape[1]
        
        plt.figure(figsize=(10, 8))
        
        colors = ['blue', 'red', 'green', 'orange', 'purple']
        
        for i in range(n_classes):
            # One-vs-rest
            y_test_binary = (y_test == i).astype(int)
            
            fpr, tpr, _ = roc_curve(y_test_binary, y_prob[:, i])
            roc_auc = auc(fpr, tpr)
            
            plt.plot(fpr, tpr, color=colors[i % len(colors)],
                    lw=2, label=f'Class {i} (AUC = {roc_auc:.2f})')
        
        plt.plot([0, 1], [0, 1], 'k--', lw=2, label='Random')
        plt.xlim([0.0, 1.0])
        plt.ylim([0.0, 1.05])
        plt.xlabel('False Positive Rate')
        plt.ylabel('True Positive Rate')
        plt.title('ROC Curves - One vs Rest')
        plt.legend(loc="lower right")
        plt.grid(alpha=0.3)
        plt.tight_layout()
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"ROC curves saved to {save_path}")
    
    def plot_learning_curve(self, X, y, save_path='evaluation/learning_curve.png'):
        """
        Plot learning curve to detect overfitting
        """
        train_sizes, train_scores, val_scores = learning_curve(
            self.model, self.scaler.transform(X), y,
            train_sizes=np.linspace(0.1, 1.0, 10),
            cv=5, n_jobs=-1, scoring='accuracy'
        )
        
        train_mean = np.mean(train_scores, axis=1)
        train_std = np.std(train_scores, axis=1)
        val_mean = np.mean(val_scores, axis=1)
        val_std = np.std(val_scores, axis=1)
        
        plt.figure(figsize=(10, 6))
        plt.plot(train_sizes, train_mean, label='Training score', color='blue', marker='o')
        plt.fill_between(train_sizes, train_mean - train_std, train_mean + train_std,
                        alpha=0.15, color='blue')
        
        plt.plot(train_sizes, val_mean, label='Cross-validation score',
                color='red', marker='o')
        plt.fill_between(train_sizes, val_mean - val_std, val_mean + val_std,
                        alpha=0.15, color='red')
        
        plt.xlabel('Training Set Size')
        plt.ylabel('Accuracy Score')
        plt.title('Learning Curve')
        plt.legend(loc='best')
        plt.grid(alpha=0.3)
        plt.tight_layout()
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"Learning curve saved to {save_path}")
    
    def analyze_misclassifications(self, X_test, y_test):
        """
        Analyze misclassified samples
        """
        X_test_scaled = self.scaler.transform(X_test)
        y_pred = self.model.predict(X_test_scaled)
        
        misclassified_idx = np.where(y_test != y_pred)[0]
        
        print(f"\n=== Misclassification Analysis ===")
        print(f"Total misclassifications: {len(misclassified_idx)} / {len(y_test)}")
        print(f"Misclassification rate: {len(misclassified_idx)/len(y_test)*100:.2f}%")
        
        # Analyze patterns in misclassifications
        misclass_data = X_test.iloc[misclassified_idx].copy()
        misclass_data['true_label'] = y_test.iloc[misclassified_idx]
        misclass_data['predicted_label'] = y_pred[misclassified_idx]
        
        # Most common misclassification patterns
        misclass_patterns = misclass_data.groupby(['true_label', 'predicted_label']).size()
        print("\nMost common misclassification patterns:")
        print(misclass_patterns.sort_values(ascending=False).head(5))
        
        return misclass_data
    
    def generate_evaluation_report(self, X_test, y_test, output_dir='evaluation'):
        """
        Generate comprehensive evaluation report
        """
        import os
        os.makedirs(output_dir, exist_ok=True)
        
        print("\n=== Generating Evaluation Report ===\n")
        
        # Evaluate
        metrics, y_pred, y_prob = self.evaluate_on_test_set(X_test, y_test)
        
        # Generate plots
        self.plot_confusion_matrix(y_test, y_pred, 
                                  f'{output_dir}/confusion_matrix.png')
        self.plot_feature_importance(top_n=15,
                                     f'{output_dir}/feature_importance.png')
        self.plot_roc_curves(X_test, y_test,
                           f'{output_dir}/roc_curves.png')
        
        # Analyze misclassifications
        misclass_data = self.analyze_misclassifications(X_test, y_test)
        
        # Save metrics
        report = {
            'evaluation_date': datetime.now().isoformat(),
            'model_type': self.model_package.get('model_type', 'unknown'),
            'test_set_size': len(X_test),
            'metrics': metrics,
            'feature_count': len(self.feature_names),
            'misclassification_count': len(misclass_data)
        }
        
        report_path = f'{output_dir}/evaluation_report.json'
        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\n=== Evaluation Report Summary ===")
        print(f"Accuracy: {metrics['accuracy']:.4f}")
        print(f"ROC AUC: {metrics.get('roc_auc', 'N/A')}")
        print(f"\nFull report saved to {report_path}")
        
        return report


class ModelComparison:
    """
    Compare multiple models
    """
    
    def __init__(self):
        self.models = {}
        self.results = {}
    
    def add_model(self, name, model_path):
        """
        Add model for comparison
        """
        model_package = joblib.load(model_path)
        self.models[name] = model_package
        print(f"Added model: {name}")
    
    def compare_models(self, X_test, y_test):
        """
        Compare all loaded models
        """
        for name, model_pkg in self.models.items():
            model = model_pkg['model']
            scaler = model_pkg['scaler']
            
            X_test_scaled = scaler.transform(X_test)
            y_pred = model.predict(X_test_scaled)
            
            accuracy = accuracy_score(y_test, y_pred)
            precision, recall, f1, _ = precision_recall_fscore_support(
                y_test, y_pred, average='weighted'
            )
            
            self.results[name] = {
                'accuracy': accuracy,
                'precision': precision,
                'recall': recall,
                'f1_score': f1
            }
        
        # Create comparison DataFrame
        comparison_df = pd.DataFrame(self.results).T
        
        print("\n=== Model Comparison ===")
        print(comparison_df.round(4))
        
        return comparison_df
    
    def plot_comparison(self, save_path='evaluation/model_comparison.png'):
        """
        Plot model comparison
        """
        if not self.results:
            print("No results to plot. Run compare_models() first.")
            return
        
        df = pd.DataFrame(self.results).T
        
        df.plot(kind='bar', figsize=(12, 6))
        plt.title('Model Performance Comparison')
        plt.ylabel('Score')
        plt.xlabel('Model')
        plt.legend(loc='best')
        plt.xticks(rotation=45)
        plt.ylim([0, 1])
        plt.grid(alpha=0.3, axis='y')
        plt.tight_layout()
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"Comparison plot saved to {save_path}")


# Example usage
if __name__ == "__main__":
    # Load test data (replace with actual data)
    df = pd.read_csv('data/test_data.csv')
    
    # Prepare test set
    X_test = df.drop(['user_id', 'down_syndrome_level'], axis=1)
    y_test = df['down_syndrome_level']
    
    # Evaluate model
    evaluator = ModelEvaluator('models/game_model.pkl')
    report = evaluator.generate_evaluation_report(X_test, y_test)
    
    print("\n=== Evaluation Complete ===")