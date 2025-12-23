import React, { useState, useEffect, useRef } from 'react';
import MessageBubble from './MessageBubble';
import InputArea from './InputArea';
import CharacterAvatar from './CharacterAvatar';
import FeedbackPanel from './FeedbackPanel';
import { useChatbot } from '../../hooks/useChatbot';
import '../../styles/chat.css';

const ChatInterface = ({ conversationId, scenario, character, onEnd }) => {
  const {
    messages,
    sendMessage,
    isLoading,
    feedback,
    error
  } = useChatbot(conversationId);

  const messagesEndRef = useRef(null);

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSendMessage = async (message, audioUrl) => {
    await sendMessage(message, audioUrl);
  };

  return (
    <div className="chat-interface">
      {/* Header */}
      <div className="chat-header">
        <CharacterAvatar character={character} size="small" />
        <div className="chat-header-info">
          <h3>{character.name}</h3>
          <p className="scenario-title">{scenario.title}</p>
        </div>
        <button 
          className="btn-end-conversation"
          onClick={onEnd}
        >
          End Chat
        </button>
      </div>

      {/* Scenario Background */}
      <div 
        className="scenario-background"
        style={{ backgroundImage: `url(${scenario.multimodal?.backgroundImage})` }}
      >
        {/* Messages Container */}
        <div className="messages-container">
          {messages.map((message, index) => (
            <MessageBubble
              key={index}
              message={message}
              isUser={message.sender === 'user'}
              showAvatar={message.sender === 'bot'}
              character={character}
            />
          ))}
          <div ref={messagesEndRef} />
        </div>

        {/* Loading Indicator */}
        {isLoading && (
          <div className="typing-indicator">
            <CharacterAvatar character={character} size="tiny" />
            <div className="typing-dots">
              <span></span>
              <span></span>
              <span></span>
            </div>
          </div>
        )}
      </div>

      {/* Feedback Panel */}
      {feedback && (
        <FeedbackPanel feedback={feedback} />
      )}

      {/* Input Area */}
      <InputArea
        onSend={handleSendMessage}
        disabled={isLoading}
        placeholder={`Reply to ${character.name}...`}
      />

      {/* Error Display */}
      {error && (
        <div className="error-banner">
          <span>⚠️ {error}</span>
        </div>
      )}
    </div>
  );
};

export default ChatInterface;