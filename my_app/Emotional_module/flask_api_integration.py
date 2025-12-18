"""
Flask API Integration for ML Model
Provides REST API endpoints for model predictions
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import numpy as np
import joblib
from datetime import datetime
import logging

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global model storage
loaded_models = {}

def load_model(model_path='models/game_model.pkl'):
    """
    Load trained ML model
    """
    try:
        model_package = joblib.load(model_path)
        logger.info(f"Model loaded successfully from {model_path}")
        return model_package
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        return None

# Load model on startup
model_package = load_model()
if model_package:
    loaded_models['game_model'] = model_package
    logger.info("Game model loaded and ready")

@app.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint
    """
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'models_loaded': list(loaded_models.keys())
    })

@app.route('/api/predict', methods=['POST'])
def predict():
    """
    Make prediction from game and sensor data
    
    Expected JSON format:
    {
        "user_id": "user_001",
        "features": {
            "avg_reaction_time": 1.5,
            "accuracy_rate": 0.85,
            "heart_rate_mean": 75.0,
            "spo2_mean": 96.0,
            ...
        }
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'features' not in data:
            return jsonify({'error': 'Missing features data'}), 400
        
        # Get model
        if 'game_model' not in loaded_models:
            return jsonify({'error': 'Model not loaded'}), 500
        
        model_pkg = loaded_models['game_model']
        model = model_pkg['model']
        scaler = model_pkg['scaler']
        feature_names = model_pkg['feature_names']
        
        # Prepare features
        features_dict = data['features']
        
        # Ensure all required features are present
        missing_features = set(feature_names) - set(features_dict.keys())
        if missing_features:
            return jsonify({
                'error': 'Missing required features',
                'missing': list(missing_features)
            }), 400
        
        # Create feature array in correct order
        feature_values = [features_dict[f] for f in feature_names]
        X = np.array(feature_values).reshape(1, -1)
        
        # Scale and predict
        X_scaled = scaler.transform(X)
        prediction = model.predict(X_scaled)[0]
        probabilities = model.predict_proba(X_scaled)[0]
        
        # Get confidence
        confidence = float(probabilities.max())
        
        # Prepare response
        response = {
            'user_id': data.get('user_id'),
            'prediction': {
                'down_syndrome_level': int(prediction),
                'confidence': confidence,
                'probabilities': {
                    f'level_{i}': float(prob) 
                    for i, prob in enumerate(probabilities)
                }
            },
            'timestamp': datetime.now().isoformat()
        }
        
        # Add interpretation
        response['interpretation'] = interpret_prediction(
            int(prediction), confidence
        )
        
        logger.info(f"Prediction made for user {data.get('user_id')}: Level {prediction}")
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/batch_predict', methods=['POST'])
def batch_predict():
    """
    Make predictions for multiple samples
    
    Expected JSON format:
    {
        "samples": [
            {"user_id": "user_001", "features": {...}},
            {"user_id": "user_002", "features": {...}}
        ]
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'samples' not in data:
            return jsonify({'error': 'Missing samples data'}), 400
        
        samples = data['samples']
        results = []
        
        for sample in samples:
            # Make individual prediction
            pred_response = make_single_prediction(sample)
            results.append(pred_response)
        
        return jsonify({
            'results': results,
            'total': len(results),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Batch prediction error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/game/analyze_session', methods=['POST'])
def analyze_game_session():
    """
    Analyze a complete game session
    
    Expected JSON format:
    {
        "session_id": "session_123",
        "user_id": "user_001",
        "game_data": {...},
        "sensor_data": {...}
    }
    """
    try:
        data = request.get_json()
        
        session_id = data.get('session_id')
        user_id = data.get('user_id')
        game_data = data.get('game_data', {})
        sensor_data = data.get('sensor_data', {})
        
        # Extract features from session
        from game_features import GameFeatureExtractor
        extractor = GameFeatureExtractor()
        
        # Combine game and sensor features
        features = {
            **game_data,
            **sensor_data
        }
        
        # Make prediction
        prediction_result = make_single_prediction({
            'user_id': user_id,
            'features': features
        })
        
        # Add session analysis
        analysis = {
            'session_id': session_id,
            'user_id': user_id,
            'prediction': prediction_result,
            'performance_summary': {
                'game_score': game_data.get('final_score', 0),
                'accuracy': game_data.get('accuracy_rate', 0),
                'reaction_time': game_data.get('avg_reaction_time', 0)
            },
            'recommendations': generate_recommendations(features, prediction_result)
        }
        
        return jsonify(analysis)
        
    except Exception as e:
        logger.error(f"Session analysis error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/model/info', methods=['GET'])
def model_info():
    """
    Get information about loaded models
    """
    if 'game_model' not in loaded_models:
        return jsonify({'error': 'Model not loaded'}), 500
    
    model_pkg = loaded_models['game_model']
    
    info = {
        'model_type': model_pkg.get('model_type', 'unknown'),
        'n_features': len(model_pkg['feature_names']),
        'feature_names': model_pkg['feature_names'],
        'trained_at': model_pkg.get('trained_at'),
        'training_history': model_pkg.get('training_history', [])
    }
    
    return jsonify(info)

@app.route('/api/model/retrain', methods=['POST'])
def retrain_model():
    """
    Trigger model retraining (admin endpoint)
    """
    try:
        data = request.get_json()
        training_data_path = data.get('training_data_path')
        
        if not training_data_path:
            return jsonify({'error': 'Missing training data path'}), 400
        
        # Load training data
        df = pd.read_csv(training_data_path)
        
        # Retrain model
        from game_model_trainer import GameModelTrainer
        trainer = GameModelTrainer(model_type='random_forest')
        X, y = trainer.prepare_data(df)
        results = trainer.train(X, y)
        
        # Save updated model
        trainer.save_model('models/game_model.pkl')
        
        # Reload model
        global loaded_models
        loaded_models['game_model'] = load_model()
        
        return jsonify({
            'status': 'success',
            'results': {
                'train_accuracy': results['train_accuracy'],
                'test_accuracy': results['test_accuracy']
            }
        })
        
    except Exception as e:
        logger.error(f"Retraining error: {str(e)}")
        return jsonify({'error': str(e)}), 500

# Helper functions

def make_single_prediction(sample):
    """
    Make prediction for a single sample
    """
    model_pkg = loaded_models['game_model']
    model = model_pkg['model']
    scaler = model_pkg['scaler']
    feature_names = model_pkg['feature_names']
    
    features_dict = sample['features']
    feature_values = [features_dict.get(f, 0) for f in feature_names]
    X = np.array(feature_values).reshape(1, -1)
    
    X_scaled = scaler.transform(X)
    prediction = model.predict(X_scaled)[0]
    probabilities = model.predict_proba(X_scaled)[0]
    
    return {
        'user_id': sample.get('user_id'),
        'prediction': int(prediction),
        'confidence': float(probabilities.max()),
        'probabilities': probabilities.tolist()
    }

def interpret_prediction(level, confidence):
    """
    Interpret prediction result
    """
    interpretations = {
        0: "Typical development - No concerns identified",
        1: "Mild indicators - Consider monitoring",
        2: "Moderate indicators - Professional assessment recommended",
        3: "Significant indicators - Immediate professional consultation advised"
    }
    
    confidence_level = "high" if confidence > 0.8 else "moderate" if confidence > 0.6 else "low"
    
    return {
        'level': level,
        'description': interpretations.get(level, "Unknown level"),
        'confidence_level': confidence_level,
        'confidence_score': confidence
    }

def generate_recommendations(features, prediction):
    """
    Generate personalized recommendations
    """
    recommendations = []
    
    level = prediction['prediction']
    
    # Based on game performance
    if features.get('accuracy_rate', 1.0) < 0.6:
        recommendations.append("Practice memory games to improve recall")
    
    if features.get('avg_reaction_time', 0) > 2.5:
        recommendations.append("Engage in activities to improve processing speed")
    
    # Based on sensor data
    if features.get('heart_rate_mean', 70) > 90:
        recommendations.append("Consider relaxation techniques before sessions")

    
    # Based on prediction level
    if level >= 2:
        recommendations.append("Consult with healthcare professional for assessment")
    
    if level == 0:
        recommendations.append("Continue regular cognitive exercises")
    
    return recommendations

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

    