import warnings
warnings.filterwarnings("ignore")

import nltk
from nltk.stem import WordNetLemmatizer
import json
import pickle
import numpy as np
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.preprocessing.sequence import pad_sequences
import random
 
from tensorflow.keras.optimizers import SGD


# WordNetLemmatizer
lemmatizer = WordNetLemmatizer()


# Load and preprocess dataset

words = []
classes = []
documents = []
ignore_words = ['?', '!']

# Load JSON
with open("Dataset/chatbotdataset.json", "r", encoding="utf-8") as file:
    intents = json.load(file)

# Determine JSON type
if isinstance(intents, dict):
    intents_data = [intents]  # wrap single dict in list
elif isinstance(intents, list):
    intents_data = intents
else:
    raise ValueError("Invalid JSON structure.")

# Download NLTK data
nltk.download('punkt')
nltk.download('wordnet')

# Convert your dataset to training format
for intent in intents_data:
    skill = intent.get('skill', None)
    responses = intent.get('responses', {})
    if not skill or not responses:
        print(f"Skipping invalid entry: {intent}")
        continue

    for level, items in responses.items():
        tag = f"{skill}_{level}"  
        for item in items:
            question = item.get('question', None)
            if question:
                w = nltk.word_tokenize(question)
                words.extend(w)
                documents.append((w, tag))
                if tag not in classes:
                    classes.append(tag)

# Lemmatization
words = [lemmatizer.lemmatize(w.lower()) for w in words if w not in ignore_words]
words = sorted(list(set(words)))
classes = sorted(list(set(classes)))

# Save words and classes
pickle.dump(words, open('Models/words.pkl', 'wb'))
pickle.dump(classes, open('Models/classes.pkl', 'wb'))


# Training set creation
training = []
output_empty = [0] * len(classes)

for doc in documents:
    bag = []
    pattern_words = [lemmatizer.lemmatize(word.lower()) for word in doc[0]]
    
    for w in words:
        bag.append(1 if w in pattern_words else 0)

    output_row = output_empty.copy()
    output_row[classes.index(doc[1])] = 1
    training.append([bag, output_row])

# Shuffle & convert
random.shuffle(training)
X = np.array([sample[0] for sample in training])
Y = np.array([sample[1] for sample in training])

# Pad sequences
X = pad_sequences(X, maxlen=len(words), padding='post')

if len(X) == 0 or len(Y) == 0:
    raise ValueError("No training data available. Check your JSON questions and tags.")


# Neural network model
model = Sequential()
model.add(Dense(128, input_shape=(len(X[0]),), activation='relu'))
model.add(Dropout(0.5))
model.add(Dense(64, activation='relu'))
model.add(Dropout(0.5))
model.add(Dense(len(Y[0]), activation='softmax'))

# Legacy SGD optimizer
sgd = SGD(learning_rate=0.01, decay=1e-6, momentum=0.9, nesterov=True)
model.compile(loss='categorical_crossentropy', optimizer=sgd, metrics=['accuracy'])


# Train model
hist = model.fit(X, Y, epochs=100, batch_size=5, verbose=1)

# Save model
model.save('Models/chatbot.h5', hist)

print("\n" + "*" * 50)
print("Model Created Successfully!")
