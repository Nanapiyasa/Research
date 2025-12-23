import React, { useState } from 'react';
import { Mic, Send, StopCircle } from 'lucide-react';
import { useVoiceInput } from '../../hooks/useVoiceInput';
import '../../styles/input-area.css';

const InputArea = ({ onSend, disabled, placeholder }) => {
  const [message, setMessage] = useState('');
  const {
    isRecording,
    startRecording,
    stopRecording,
    transcript,
    audioUrl
  } = useVoiceInput();

  // Update message when transcript changes
  React.useEffect(() => {
    if (transcript) {
      setMessage(transcript);
    }
  }, [transcript]);

  const handleSend = () => {
    if (message.trim()) {
      onSend(message, audioUrl);
      setMessage('');
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const toggleRecording = () => {
    if (isRecording) {
      stopRecording();
    } else {
      startRecording();
    }
  };

  return (
    <div className="input-area">
      <div className="input-container">
        {/* Voice Input Button */}
        <button
          className={`btn-voice ${isRecording ? 'recording' : ''}`}
          onClick={toggleRecording}
          disabled={disabled}
          title={isRecording ? 'Stop recording' : 'Start recording'}
        >
          {isRecording ? (
            <StopCircle size={24} className="icon-pulse" />
          ) : (
            <Mic size={24} />
          )}
        </button>

        {/* Text Input */}
        <textarea
          className="message-input"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder={placeholder}
          disabled={disabled || isRecording}
          rows={1}
        />

        {/* Send Button */}
        <button
          className="btn-send"
          onClick={handleSend}
          disabled={disabled || !message.trim()}
          title="Send message"
        >
          <Send size={24} />
        </button>
      </div>

      {/* Recording Indicator */}
      {isRecording && (
        <div className="recording-indicator">
          <div className="recording-pulse"></div>
          <span>Recording... Tap to stop</span>
        </div>
      )}
    </div>
  );
};

export default InputArea;