import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from transformers import BertTokenizer, BertForSequenceClassification, Trainer, TrainingArguments
import torch
from torch.utils.data import Dataset
import json

class IntentDataset(Dataset):
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

def load_training_data():
    """Load and prepare training data for intent classification"""
    # Sample training data structure
    data = {
        'text': [
            'hello there', 'hi how are you', 'hey!', 'good morning',  # greetings
            'goodbye', 'see you later', 'bye bye', 'have a nice day',  # farewells
            'can you help me', 'please give me', 'I need', 'could you',  # requests
            'what is that', 'where are you', 'how do I', 'why is',  # questions
            'I think so', 'that is correct', 'yes please', 'okay sure',  # agreements
            'I am sorry', 'my apologies', 'sorry about that',  # apologies
            'thank you', 'thanks a lot', 'appreciate it',  # thanks
        ],
        'intent': [
            0, 0, 0, 0,  # greeting
            1, 1, 1, 1,  # farewell
            2, 2, 2, 2,  # request
            3, 3, 3, 3,  # question
            4, 4, 4, 4,  # agreement
            5, 5, 5,     # apology
            6, 6, 6,     # thanks
        ]
    }
    
    df = pd.DataFrame(data)
    return df

def train_intent_classifier():
    """Train BERT-based intent classifier"""
    print("Loading training data...")
    df = load_training_data()
    
    # Intent mapping
    intent_map = {
        0: 'greeting',
        1: 'farewell',
        2: 'request',
        3: 'question',
        4: 'agreement',
        5: 'apology',
        6: 'thanks',
        7: 'statement'
    }
    
    # Split data
    train_texts, val_texts, train_labels, val_labels = train_test_split(
        df['text'].values,
        df['intent'].values,
        test_size=0.2,
        random_state=42
    )
    
    print("Initializing tokenizer and model...")
    tokenizer = BertTokenizer.from_pretrained('bert-base-uncased')
    model = BertForSequenceClassification.from_pretrained(
        'bert-base-uncased',
        num_labels=len(intent_map)
    )
    
    # Create datasets
    train_dataset = IntentDataset(train_texts, train_labels, tokenizer)
    val_dataset = IntentDataset(val_texts, val_labels, tokenizer)
    
    # Training arguments
    training_args = TrainingArguments(
        output_dir='./models/intent_classifier',
        num_train_epochs=3,
        per_device_train_batch_size=8,
        per_device_eval_batch_size=8,
        warmup_steps=100,
        weight_decay=0.01,
        logging_dir='./logs',
        logging_steps=10,
        evaluation_strategy='epoch',
        save_strategy='epoch',
        load_best_model_at_end=True
    )
    
    # Initialize trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=val_dataset
    )
    
    print("Starting training...")
    trainer.train()
    
    # Save model
    print("Saving model...")
    model.save_pretrained('./models/intent_classifier_final')
    tokenizer.save_pretrained('./models/intent_classifier_final')
    
    # Save intent mapping
    with open('./models/intent_classifier_final/intent_map.json', 'w') as f:
        json.dump(intent_map, f)
    
    print("Training complete!")

if __name__ == '__main__':
    train_intent_classifier()
