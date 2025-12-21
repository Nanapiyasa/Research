"""
Game Interaction Module
Handles cognitive flip card game data collection and analysis
"""

import json
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Tuple

class GameInteractionTracker:
    """
    Tracks user interactions during cognitive flip card game sessions
    """
    
    def __init__(self):
        self.session_data = []
        self.current_session = None
        
    def start_session(self, user_id: str, difficulty_level: int = 1):
        """
        Initialize a new game session
        """
        self.current_session = {
            'session_id': f"{user_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            'user_id': user_id,
            'start_time': datetime.now(),
            'difficulty_level': difficulty_level,
            'card_pairs': difficulty_level * 4,  # 4, 8, 12, 16 pairs
            'moves': [],
            'matches': [],
            'mistakes': 0,
            'completed': False
        }
        print(f"Session started: {self.current_session['session_id']}")
        return self.current_session['session_id']
    
    def record_card_flip(self, card_id: int, position: Tuple[int, int], 
                        timestamp: datetime = None):
        """
        Record individual card flip action
        """
        if not self.current_session:
            raise ValueError("No active session. Call start_session() first.")
        
        move = {
            'card_id': card_id,
            'position': position,
            'timestamp': timestamp or datetime.now(),
            'move_number': len(self.current_session['moves']) + 1
        }
        
        self.current_session['moves'].append(move)
        
        # Check for match if this is second card in pair
        if len(self.current_session['moves']) % 2 == 0:
            self._check_match()
    
    def _check_match(self):
        """
        Check if last two cards form a match
        """
        last_two = self.current_session['moves'][-2:]
        card1, card2 = last_two[0], last_two[1]
        
        # Calculate reaction time
        reaction_time = (card2['timestamp'] - card1['timestamp']).total_seconds()
        
        # Check if cards match (same card_id means matching pair)
        is_match = card1['card_id'] == card2['card_id']
        
        match_record = {
            'card1': card1,
            'card2': card2,
            'is_match': is_match,
            'reaction_time': reaction_time,
            'timestamp': card2['timestamp']
        }
        
        self.current_session['matches'].append(match_record)
        
        if not is_match:
            self.current_session['mistakes'] += 1
        
        # Check if game completed
        expected_pairs = self.current_session['card_pairs']
        successful_matches = sum(1 for m in self.current_session['matches'] if m['is_match'])
        
        if successful_matches == expected_pairs:
            self.end_session()
    
    def end_session(self):
        """
        End current game session and calculate metrics
        """
        if not self.current_session:
            return None
        
        self.current_session['end_time'] = datetime.now()
        self.current_session['completed'] = True
        
        # Calculate session metrics
        metrics = self._calculate_session_metrics()
        self.current_session['metrics'] = metrics
        
        # Save session
        self.session_data.append(self.current_session)
        
        print(f"Session ended: {self.current_session['session_id']}")
        print(f"Score: {metrics['final_score']}")
        
        session = self.current_session
        self.current_session = None
        
        return session
    
    def _calculate_session_metrics(self) -> Dict:
        """
        Calculate comprehensive game performance metrics
        """
        start = self.current_session['start_time']
        end = self.current_session['end_time']
        total_time = (end - start).total_seconds()
        
        matches = self.current_session['matches']
        successful_matches = [m for m in matches if m['is_match']]
        
        # Reaction times
        reaction_times = [m['reaction_time'] for m in matches]
        avg_reaction_time = np.mean(reaction_times) if reaction_times else 0
        
        # Accuracy
        total_attempts = len(matches)
        accuracy = len(successful_matches) / total_attempts if total_attempts > 0 else 0
        
        # Score calculation (higher is better)
        base_score = accuracy * 100
        time_penalty = min(total_time / 60, 5) * 2  # Max 10 point penalty
        mistake_penalty = self.current_session['mistakes'] * 3
        
        final_score = max(0, base_score - time_penalty - mistake_penalty)
        
        return {
            'total_time': total_time,
            'total_moves': len(self.current_session['moves']),
            'total_attempts': total_attempts,
            'successful_matches': len(successful_matches),
            'mistakes': self.current_session['mistakes'],
            'accuracy': accuracy,
            'avg_reaction_time': avg_reaction_time,
            'min_reaction_time': min(reaction_times) if reaction_times else 0,
            'max_reaction_time': max(reaction_times) if reaction_times else 0,
            'final_score': round(final_score, 2)
        }
    
    def get_session_dataframe(self) -> pd.DataFrame:
        """
        Convert session data to pandas DataFrame for analysis
        """
        if not self.session_data:
            return pd.DataFrame()
        
        records = []
        for session in self.session_data:
            record = {
                'session_id': session['session_id'],
                'user_id': session['user_id'],
                'start_time': session['start_time'],
                'end_time': session.get('end_time'),
                'difficulty_level': session['difficulty_level'],
                'card_pairs': session['card_pairs'],
                'completed': session['completed']
            }
            
            # Add metrics
            if 'metrics' in session:
                record.update(session['metrics'])
            
            records.append(record)
        
        return pd.DataFrame(records)
    
    def export_sessions(self, filepath: str = 'data/game_sessions.json'):
        """
        Export session data to JSON file
        """
        # Convert datetime objects to strings
        export_data = []
        for session in self.session_data:
            session_copy = session.copy()
            session_copy['start_time'] = session_copy['start_time'].isoformat()
            if session_copy.get('end_time'):
                session_copy['end_time'] = session_copy['end_time'].isoformat()
            
            # Convert move timestamps
            for move in session_copy['moves']:
                move['timestamp'] = move['timestamp'].isoformat()
            
            for match in session_copy['matches']:
                match['timestamp'] = match['timestamp'].isoformat()
                match['card1']['timestamp'] = match['card1']['timestamp'].isoformat()
                match['card2']['timestamp'] = match['card2']['timestamp'].isoformat()
            
            export_data.append(session_copy)
        
        with open(filepath, 'w') as f:
            json.dump(export_data, f, indent=2)
        
        print(f"Sessions exported to {filepath}")


class CognitiveMetricsAnalyzer:
    """
    Analyzes cognitive performance from game interaction data
    """
    
    def __init__(self, session_df: pd.DataFrame):
        self.df = session_df
    
    def calculate_cognitive_score(self) -> pd.DataFrame:
        """
        Calculate comprehensive cognitive performance score
        """
        df = self.df.copy()
        
        # Normalize metrics to 0-1 scale
        df['accuracy_norm'] = df['accuracy']
        df['reaction_time_norm'] = 1 - (df['avg_reaction_time'] / df['avg_reaction_time'].max())
        df['completion_time_norm'] = 1 - (df['total_time'] / df['total_time'].max())
        
        # Weighted cognitive score
        df['cognitive_score'] = (
            df['accuracy_norm'] * 0.4 +
            df['reaction_time_norm'] * 0.3 +
            df['completion_time_norm'] * 0.2 +
            (df['final_score'] / 100) * 0.1
        ) * 100
        
        return df
    
    def detect_performance_trends(self, user_id: str) -> Dict:
        """
        Detect performance trends for a specific user
        """
        user_data = self.df[self.df['user_id'] == user_id].sort_values('start_time')
        
        if len(user_data) < 2:
            return {'trend': 'insufficient_data'}
        
        # Calculate rolling averages
        window = min(5, len(user_data))
        user_data['accuracy_trend'] = user_data['accuracy'].rolling(window=window).mean()
        user_data['score_trend'] = user_data['final_score'].rolling(window=window).mean()
        
        # Determine trend direction
        recent_accuracy = user_data['accuracy'].tail(3).mean()
        early_accuracy = user_data['accuracy'].head(3).mean()
        
        improvement = ((recent_accuracy - early_accuracy) / early_accuracy * 100 
                      if early_accuracy > 0 else 0)
        
        return {
            'trend': 'improving' if improvement > 5 else 'declining' if improvement < -5 else 'stable',
            'improvement_percentage': round(improvement, 2),
            'current_accuracy': round(recent_accuracy, 3),
            'average_score': round(user_data['final_score'].mean(), 2),
            'total_sessions': len(user_data)
        }
    
    def compare_difficulty_levels(self) -> pd.DataFrame:
        """
        Compare performance across different difficulty levels
        """
        comparison = self.df.groupby('difficulty_level').agg({
            'accuracy': 'mean',
            'avg_reaction_time': 'mean',
            'total_time': 'mean',
            'final_score': 'mean',
            'mistakes': 'mean'
        }).round(3)
        
        return comparison
    
    def identify_struggling_areas(self, user_id: str) -> Dict:
        """
        Identify areas where user struggles most
        """
        user_data = self.df[self.df['user_id'] == user_id]
        
        if user_data.empty:
            return {'status': 'no_data'}
        
        avg_accuracy = user_data['accuracy'].mean()
        avg_reaction = user_data['avg_reaction_time'].mean()
        avg_mistakes = user_data['mistakes'].mean()
        
        struggles = []
        
        if avg_accuracy < 0.6:
            struggles.append('memory_recall')
        if avg_reaction > 2.5:
            struggles.append('processing_speed')
        if avg_mistakes > 5:
            struggles.append('pattern_recognition')
        
        return {
            'struggling_areas': struggles,
            'avg_accuracy': round(avg_accuracy, 3),
            'avg_reaction_time': round(avg_reaction, 3),
            'avg_mistakes': round(avg_mistakes, 1),
            'recommendation': self._generate_recommendation(struggles)
        }
    
    def _generate_recommendation(self, struggles: List[str]) -> str:
        """
        Generate training recommendations based on struggles
        """
        if not struggles:
            return "Excellent performance! Consider increasing difficulty level."
        
        recommendations = {
            'memory_recall': "Practice with fewer cards and gradually increase difficulty.",
            'processing_speed': "Take your time initially. Speed will improve with practice.",
            'pattern_recognition': "Focus on card positions and develop a systematic approach."
        }
        
        return " ".join([recommendations.get(s, "") for s in struggles])


# Example usage
if __name__ == "__main__":
    # Initialize tracker
    tracker = GameInteractionTracker()
    
    # Simulate a game session
    session_id = tracker.start_session(user_id="user_001", difficulty_level=2)
    
    # Simulate card flips (8 pairs = 16 cards)
    # Format: (card_id, position)
    moves = [
        (1, (0, 0)), (2, (0, 1)),  # No match
        (3, (1, 0)), (3, (1, 1)),  # Match!
        (1, (0, 0)), (1, (2, 0)),  # Match!
        (4, (2, 1)), (5, (2, 2)),  # No match
        (2, (0, 1)), (2, (3, 0)),  # Match!
        # ... continue for all pairs
    ]
    
    start_time = datetime.now()
    for i, (card_id, position) in enumerate(moves):
        timestamp = start_time + timedelta(seconds=i*2 + np.random.uniform(0.5, 2))
        tracker.record_card_flip(card_id, position, timestamp)
        
    
    # Get session data
    df = tracker.get_session_dataframe()
    print("\n=== Session Summary ===")
    print(df[['user_id', 'difficulty_level', 'final_score', 'accuracy', 'mistakes']])
    
    # Analyze cognitive metrics
    analyzer = CognitiveMetricsAnalyzer(df)
    cognitive_df = analyzer.calculate_cognitive_score()
    print("\n=== Cognitive Scores ===")
    print(cognitive_df[['user_id', 'cognitive_score', 'accuracy', 'avg_reaction_time']])
    
    # Export data
    tracker.export_sessions('data/game_sessions.json')