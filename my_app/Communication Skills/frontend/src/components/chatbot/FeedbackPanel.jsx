
import React from 'react';
import { motion } from 'framer-motion';
import { Star, ThumbsUp, Lightbulb } from 'lucide-react';
import '../../styles/feedback-panel.css';

const FeedbackPanel = ({ feedback }) => {
  if (!feedback) return null;

  const getFeedbackIcon = (type) => {
    switch (type) {
      case 'positive':
        return <Star className="icon-gold" size={20} />;
      case 'encouraging':
        return <ThumbsUp className="icon-blue" size={20} />;
      case 'corrective':
        return <Lightbulb className="icon-yellow" size={20} />;
      default:
        return null;
    }
  };

  return (
    <motion.div
      className="feedback-panel"
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.3 }}
    >
      <div className="feedback-header">
        {getFeedbackIcon(feedback.type)}
        <span className="feedback-message">{feedback.message}</span>
      </div>

      {feedback.suggestions && feedback.suggestions.length > 0 && (
        <div className="feedback-suggestions">
          <p className="suggestions-title">💡 Tips:</p>
          <ul>
            {feedback.suggestions.map((suggestion, index) => (
              <li key={index}>{suggestion}</li>
            ))}
          </ul>
        </div>
      )}
    </motion.div>
  );
};

export default FeedbackPanel;