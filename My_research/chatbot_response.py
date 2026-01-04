import warnings
warnings.filterwarnings("ignore")

import nltk
from nltk.stem import WordNetLemmatizer
import numpy as np
import pickle
import json
import random
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences


# Paths
MODEL_PATH = "Models/chatbot.h5"
WORDS_PATH = "Models/words.pkl"
CLASSES_PATH = "Models/classes.pkl"
INTENTS_PATH = "Dataset/chatbotdataset.json"


# Load data
lemmatizer = WordNetLemmatizer()

try:
    model = load_model(MODEL_PATH)
except OSError:
    raise FileNotFoundError(f"Model not found at {MODEL_PATH}. Make sure to train it first.")

with open(WORDS_PATH, "rb") as f:
    words = pickle.load(f)

with open(CLASSES_PATH, "rb") as f:
    classes = pickle.load(f)

with open(INTENTS_PATH, "r", encoding="utf-8") as f:
    intents = json.load(f)

# Ensure intents is a list
if isinstance(intents, dict):
    intents = [intents]


# Helper functions
def clean_up_sentence(sentence):
    sentence_words = nltk.word_tokenize(sentence)
    sentence_words = [lemmatizer.lemmatize(word.lower()) for word in sentence_words]
    return sentence_words

def bow(sentence, words, show_details=False):
    sentence_words = clean_up_sentence(sentence)
    bag = [1 if w in sentence_words else 0 for w in words]
    return np.array(bag)

def predict_class(sentence):
    p = bow(sentence, words)
    p = pad_sequences([p], maxlen=len(words), padding='post')
    res = model.predict(p, verbose=0)[0]
    ERROR_THRESHOLD = 0.25
    results = [(i, r) for i, r in enumerate(res) if r > ERROR_THRESHOLD]
    results.sort(key=lambda x: x[1], reverse=True)
    if results:
        return classes[results[0][0]]
    else:
        return None

def get_response_from_intent(tag):
    for intent in intents:
        skill = intent.get("skill")
        responses = intent.get("responses", {})
        for level, items in responses.items():
            intent_tag = f"{skill}_{level}"
            if intent_tag == tag:
                all_answers = []
                for item in items:
                    answers = item.get("answers", [])
                    all_answers.extend(answers)
                if all_answers:
                    return random.choice(all_answers)
    return "Sorry, I don't understand."

def chatbot_response(text):
    intent_tag = predict_class(text)
    if intent_tag:
        response = get_response_from_intent(intent_tag)
        return response
    else:
        return "Sorry, I don't understand."


if __name__ == "__main__":
    print("Chatbot is running! Type 'quit' to exit.")
    while True:
        text = input("You: ")
        if text.lower() == "quit":
            break
        response = chatbot_response(text)
        print("Bot:", response)
