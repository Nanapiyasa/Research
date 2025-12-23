
import React from 'react';
import { motion } from 'framer-motion';
import CharacterAvatar from './CharacterAvatar';
import '../../styles/message-bubble.css';

const MessageBubble = ({ message, isUser, showAvatar, character }) => {
  const bubbleVariants = {
    hidden: { 
      opacity: 0, 
      y: 20,
      scale: 0.8
    },
    visible: { 
      opacity: 1, 
      y: 0,
      scale: 1,
      transition: {
        duration: 0.3,
        ease: 'easeOut'
      }
    }
  };

  return (
    <motion.div
      className={`message-bubble-container ${isUser ? 'user' : 'bot'}`}
      variants={bubbleVariants}
      initial="hidden"
      animate="visible"
    >
      {showAvatar && !isUser && (
        <CharacterAvatar character={character} size="small" />
      )}
      
      <div className={`message-bubble ${isUser ? 'user-bubble' : 'bot-bubble'}`}>
        <p className="message-text">{message.content.text}</p>
        
        {message.content.audio && (
          <audio controls className="message-audio">
            <source src={message.content.audio} type="audio/mpeg" />
          </audio>
        )}

        {/* Analysis badges for user messages */}
        {isUser && message.analysis && (
          <div className="message-analysis">
            {message.analysis.emotion && (
              <span className={`badge emotion-${message.analysis.emotion}`}>
                {getEmotionEmoji(message.analysis.emotion)}
              </span>
            )}
            {message.analysis.responseQuality >= 80 && (
              <span className="badge quality-high">⭐</span>
            )}
          </div>
        )}
      </div>

      <span className="message-time">
        {new Date(message.timestamp).toLocaleTimeString([], { 
          hour: '2-digit', 
          minute: '2-digit' 
        })}
      </span>
    </motion.div>
  );
};

const getEmotionEmoji = (emotion) => {
  const emojiMap = {
    happy: '😊',
    sad: '😢',
    angry: '😠',
    confused: '😕',
    excited: '🤩',
    neutral: '😐'
  };
  return emojiMap[emotion] || '😐';
};

export default MessageBubble;