import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from transformers import RobertaTokenizer, RobertaForSequenceClassification, Trainer, TrainingArguments
import torch
from torch.utils.data import Dataset
import json

class EmotionDataset(Dataset):
    def __init__(self, texts, labels, tokenizer, max_length=128):
        self.texts = texts
        self.labels = labels
        self.tokenizer = tokenizer
        self.max_length = max_length

    def __len__(self):
        return len(self.texts)

    def __getitem__(self, idx):
        text = str(self.texts[idx])
        label = self.labels[idx]

        encoding = self.tokenizer(
            text,
            add_special_tokens=True,
            max_length=self.max_length,
            padding='max_length',
            truncation=True,
            return_tensors='pt'
        )

        return {
            'input_ids': encoding['input_ids'].flatten(),
            'attention_mask': encoding['attention_mask'].flatten(),
            'labels': torch.tensor(label, dtype=torch.long)
        }

def load_emotion_data():
    """Load training data for emotion detection"""
    data = {
        'text': [
            'I am so happy today!', 'This is wonderful!', 'I love this!',  # happy
            'I feel sad', 'This is disappointing', 'I am upset',  # sad
            'This makes me angry', 'I am furious', 'This is frustrating',  # angry
            'I don\'t understand', 'This is confusing', 'I am puzzled',  # confused
            'I am so excited!', 'This is amazing!', 'Wow!',  # excited
            'Okay', 'I see', 'Alright',  # neutral
        ],
        'emotion': [
            0, 0, 0,  # happy
            1, 1, 1,  # sad
            2, 2, 2,  # angry
            3, 3, 3,  # confused
            4, 4, 4,  # excited
            5, 5, 5,  # neutral
        ]
    }
    
    return pd.DataFrame(data)

def train_emotion_detector():
    """Train RoBERTa-based emotion detector"""
    print("Loading emotion data...")
    df = load_emotion_data()
    
    emotion_map = {
        0: 'happy',
        1: 'sad',
        2: 'angry',
        3: 'confused',
        4: 'excited',
        5: 'neutral'
    }
    
    # Split data
    train_texts, val_texts, train_labels, val_labels = train_test_split(
        df['text'].values,
        df['emotion'].values,
        test_size=0.2,
        random_state=42
    )
    
    print("Initializing model...")
    tokenizer = RobertaTokenizer.from_pretrained('roberta-base')
    model = RobertaForSequenceClassification.from_pretrained(
        'roberta-base',
        num_labels=len(emotion_map)
    )
    
    # Create datasets
    train_dataset = EmotionDataset(train_texts, train_labels, tokenizer)
    val_dataset = EmotionDataset(val_texts, val_labels, tokenizer)
    
    # Training arguments
    training_args = TrainingArguments(
        output_dir='./models/emotion_detector',
        num_train_epochs=3,
        per_device_train_batch_size=8,
        per_device_eval_batch_size=8,
        warmup_steps=100,
        weight_decay=0.01,
        logging_dir='./logs',
        evaluation_strategy='epoch',
        save_strategy='epoch'
    )
    
    # Train
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=val_dataset
    )
    
    print("Training emotion detector...")
    trainer.train()
    
    # Save
    model.save_pretrained('./models/emotion_detector_final')
    tokenizer.save_pretrained('./models/emotion_detector_final')
    
    with open('./models/emotion_detector_final/emotion_map.json', 'w') as f:
        json.dump(emotion_map, f)
    
    print("Emotion detector training complete!")

if __name__ == '__main__':
    train_emotion_detector()