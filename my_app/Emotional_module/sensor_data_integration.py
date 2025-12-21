"""
Sensor Data Integration Module
Combines sensor data (Heart Rate, SpO2) with game interaction data
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Tuple

class SensorGameIntegrator:
    """
    Integrate sensor readings with game session data
    """
    
    def __init__(self):
        self.synchronized_data = []
    
    def load_sensor_data(self, filepath: str) -> pd.DataFrame:
        """
        Load sensor data from file
        Expected columns: timestamp, user_id, heart_rate, spo2
        """
        df = pd.read_csv(filepath)
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df = df.sort_values(['user_id', 'timestamp'])
        
        print(f"Loaded {len(df)} sensor readings")
        return df
    
    def load_game_sessions(self, filepath: str) -> List[Dict]:
        """
        Load game session data from JSON
        """
        import json
        with open(filepath, 'r') as f:
            sessions = json.load(f)
        
        # Convert timestamp strings back to datetime
        for session in sessions:
            session['start_time'] = datetime.fromisoformat(session['start_time'])
            if session.get('end_time'):
                session['end_time'] = datetime.fromisoformat(session['end_time'])
        
        print(f"Loaded {len(sessions)} game sessions")
        return sessions
    
    def synchronize_data(self, sensor_df: pd.DataFrame, 
                        game_sessions: List[Dict],
                        window_seconds: int = 300) -> pd.DataFrame:
        """
        Synchronize sensor data with game sessions
        """
        print("\nSynchronizing sensor and game data...")
        
        synchronized_records = []
        
        for session in game_sessions:
            user_id = session['user_id']
            start_time = session['start_time']
            end_time = session.get('end_time', start_time + timedelta(minutes=10))
            
            # Get sensor data for this user during game session
            user_sensor = sensor_df[
                (sensor_df['user_id'] == user_id) &
                (sensor_df['timestamp'] >= start_time - timedelta(seconds=window_seconds)) &
                (sensor_df['timestamp'] <= end_time + timedelta(seconds=window_seconds))
            ]
            
            if user_sensor.empty:
                print(f"Warning: No sensor data for session {session['session_id']}")
                continue
            
            # Calculate sensor statistics during game
            sensor_stats = {
                'heart_rate_mean': user_sensor['heart_rate'].mean(),
                'heart_rate_std': user_sensor['heart_rate'].std(),
                'heart_rate_min': user_sensor['heart_rate'].min(),
                'heart_rate_max': user_sensor['heart_rate'].max(),
                'spo2_mean': user_sensor['spo2'].mean(),
                'spo2_std': user_sensor['spo2'].std(),
                'spo2_min': user_sensor['spo2'].min(),
                'spo2_max': user_sensor['spo2'].max()
            }
            
            # Combine with game metrics
            record = {
                'session_id': session['session_id'],
                'user_id': user_id,
                'start_time': start_time,
                'difficulty_level': session['difficulty_level']
            }
            
            # Add sensor stats
            record.update(sensor_stats)
            
            # Add game metrics
            if 'metrics' in session:
                metrics = session['metrics']
                record.update({
                    'game_score': metrics['final_score'],
                    'accuracy': metrics['accuracy'],
                    'avg_reaction_time': metrics['avg_reaction_time'],
                    'total_time': metrics['total_time'],
                    'mistakes': metrics['mistakes']
                })
            
            synchronized_records.append(record)
        
        df = pd.DataFrame(synchronized_records)
        print(f"Synchronized {len(df)} records")
        
        return df
    
    def calculate_physiological_stress(self, sensor_data: pd.DataFrame) -> pd.DataFrame:
        """
        Calculate stress indicators from sensor data
        """
        df = sensor_data.copy()
        
        # Heart rate variability (HRV) - simplified
        df['hr_variability'] = df.groupby('user_id')['heart_rate'].transform(
            lambda x: x.rolling(window=5, min_periods=1).std()
        )
        
        # Stress index (elevated HR + low HRV suggests stress)
        baseline_hr = df.groupby('user_id')['heart_rate'].transform('mean')
        df['hr_elevation'] = (df['heart_rate'] - baseline_hr) / baseline_hr
        
        # Normalize to 0-1 scale
        df['stress_index'] = (df['hr_elevation'] * 0.6 + 
                             (1 - df['spo2'] / 100) * 0.4).clip(0, 1)
        
        return df
    
    def detect_anomalies(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Detect anomalous sensor readings during game sessions
        """
        df = df.copy()
        
        # Z-score based anomaly detection
        for col in ['heart_rate_mean', 'spo2_mean']:
            mean = df[col].mean()
            std = df[col].std()
            df[f'{col}_zscore'] = (df[col] - mean) / std
            df[f'{col}_anomaly'] = df[f'{col}_zscore'].abs() > 3
        
        # Flag sessions with anomalies
        df['has_anomaly'] = (df['heart_rate_mean_anomaly'] | 
                            df['spo2_mean_anomaly'])
        
        anomaly_count = df['has_anomaly'].sum()
        print(f"Detected {anomaly_count} sessions with anomalous sensor readings")
        
        return df
    
    def create_temporal_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Create time-based features
        """
        df = df.copy()
        
        # Time of day features
        df['hour'] = pd.to_datetime(df['start_time']).dt.hour
        df['day_of_week'] = pd.to_datetime(df['start_time']).dt.dayofweek
        
        # Categorize time of day
        df['time_of_day'] = pd.cut(df['hour'], 
                                   bins=[0, 6, 12, 18, 24],
                                   labels=['night', 'morning', 'afternoon', 'evening'])
        
        # Session sequence number per user
        df['session_number'] = df.groupby('user_id').cumcount() + 1
        
        return df
    
    def calculate_combined_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Calculate features combining sensor and game data
        """
        df = df.copy()
        
        # Performance under stress
        df['performance_under_stress'] = (
            df['game_score'] / (1 + df['heart_rate_std'])
        )
        
        # Cognitive load indicator
        df['cognitive_load'] = (
            df['heart_rate_elevation'] * 0.4 +
            (1 - df['accuracy']) * 0.3 +
            (df['avg_reaction_time'] / 3) * 0.3
        ).clip(0, 1)
        
        # Oxygen efficiency
        df['oxygen_efficiency'] = df['game_score'] * df['spo2_mean'] / 100
        
        # Fatigue indicator
        df['fatigue_indicator'] = (
            df['heart_rate_elevation'] * 0.5 +
            (100 - df['spo2_mean']) / 10 * 0.5
        ).clip(0, 1)
        
        return df
    
    def aggregate_user_history(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Create aggregated features from user history
        """
        user_agg = df.groupby('user_id').agg({
            'game_score': ['mean', 'std', 'max', 'min'],
            'accuracy': ['mean', 'std'],
            'heart_rate_mean': ['mean', 'std'],
            'spo2_mean': ['mean', 'std'],
            'session_number': 'max'  # Total sessions
        })
        
        # Flatten column names
        user_agg.columns = ['_'.join(col).strip() for col in user_agg.columns]
        user_agg = user_agg.add_prefix('user_history_')
        
        # Merge back to main dataframe
        df = df.merge(user_agg, left_on='user_id', right_index=True, how='left')
        
        # Calculate improvement trend
        df['score_improvement'] = (
            df['game_score'] - df['user_history_game_score_mean']
        ) / (df['user_history_game_score_std'] + 1)
        
        return df
    
    def export_integrated_data(self, df: pd.DataFrame, 
                              filepath: str = 'data/integrated_data.csv'):
        """
        Export integrated dataset
        """
        df.to_csv(filepath, index=False)
        
        # Create summary
        summary = {
            'total_records': len(df),
            'unique_users': df['user_id'].nunique(),
            'date_range': {
                'start': df['start_time'].min().isoformat(),
                'end': df['start_time'].max().isoformat()
            },
            'features': list(df.columns),
            'anomaly_rate': float(df.get('has_anomaly', pd.Series([False])).mean()),
            'avg_game_score': float(df['game_score'].mean()),
            'avg_heart_rate': float(df['heart_rate_mean'].mean()),
            'avg_spo2': float(df['spo2_mean'].mean())
        }
        
        import json
        summary_path = filepath.replace('.csv', '_summary.json')
        with open(summary_path, 'w') as f:
            json.dump(summary, f, indent=2)
        
        print(f"\nIntegrated data exported to {filepath}")
        print(f"Summary saved to {summary_path}")
        
        return summary


# Example usage
if __name__ == "__main__":
    # Initialize integrator
    integrator = SensorGameIntegrator()
    
    # Generate sample data for demonstration
    np.random.seed(42)
    n_readings = 10000
    
    # Sample sensor data
    sensor_data = pd.DataFrame({
        'timestamp': pd.date_range('2024-01-01', periods=n_readings, freq='10s'),
        'user_id': np.random.choice(['user_001', 'user_002', 'user_003'], n_readings),
        'heart_rate': np.random.normal(75, 15, n_readings),
        'spo2': np.random.normal(96, 2, n_readings)
    })
    
    print("=== Sensor Data Integration Pipeline ===\n")
    

    
    # Calculate physiological stress
    sensor_data = integrator.calculate_physiological_stress(sensor_data)

    
    
    # For full integration, you would:
    # 1. Load game sessions
    # game_sessions = integrator.load_game_sessions('data/game_sessions.json')
    
    # 2. Synchronize data
    # integrated_df = integrator.synchronize_data(sensor_data, game_sessions)
    
    # 3. Create combined features
    # integrated_df = integrator.create_temporal_features(integrated_df)
    # integrated_df = integrator.calculate_combined_features(integrated_df)
    
    # 4. Detect anomalies
    # integrated_df = integrator.detect_anomalies(integrated_df)
    
    # 5. Export
    # summary = integrator.export_integrated_data(integrated_df)
    
    print("\n=== Sensor Data Sample ===")
    print(sensor_data[['timestamp', 'user_id', 'heart_rate', 'spo2', 'stress_index']].head(10))