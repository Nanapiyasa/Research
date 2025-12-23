import { useState, useEffect } from 'react';
import io from 'socket.io-client';
import chatbotService from '../services/chatbot.service';

export const useChatbot = (conversationId) => {
  const [messages, setMessages] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [error, setError] = useState(null);
  const [socket, setSocket] = useState(null);

  // Initialize WebSocket connection
  useEffect(() => {
    if (!conversationId) return;

    const newSocket = io(process.env.REACT_APP_API_URL || 'http://localhost:5000');
    
    newSocket.on('connect', () => {
      newSocket.emit('join_conversation', conversationId);
    });

    newSocket.on('new_message', (message) => {
      setMessages(prev => [...prev, message]);
      setIsLoading(false);
    });

    setSocket(newSocket);

    // Load conversation history
    loadConversation();

    return () => {
      newSocket.disconnect();
    };
  }, [conversationId]);

  const loadConversation = async () => {
    try {
      const conversation = await chatbotService.getConversation(conversationId);
      setMessages(conversation.messages);
    } catch (err) {
      setError('Failed to load conversation');
    }
  };

  const sendMessage = async (message, audioUrl = null) => {
    try {
      setIsLoading(true);
      setError(null);

      // Add user message immediately for better UX
      const userMessage = {
        sender: 'user',
        content: { text: message, audio: audioUrl },
        timestamp: new Date()
      };
      setMessages(prev => [...prev, userMessage]);

      // Send to backend
      const response = await chatbotService.sendMessage(conversationId, {
        message,
        audioUrl
      });

      // Update feedback
      if (response.feedback) {
        setFeedback(response.feedback);
        setTimeout(() => setFeedback(null), 5000);
      }

      // Bot message will come via WebSocket
    } catch (err) {
      setError('Failed to send message');
      setIsLoading(false);
    }
  };

  return {
    messages,
    sendMessage,
    isLoading,
    feedback,
    error
  };
};