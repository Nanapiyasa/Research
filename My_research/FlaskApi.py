from flask import Flask, request, jsonify
import json
import random
import pickle
import numpy as np
import nltk
from nltk.stem import WordNetLemmatizer
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences
from model_predict import predict_new_players


# App Setup
app = Flask(__name__)

lemmatizer = WordNetLemmatizer()
nltk.download("punkt")
nltk.download("wordnet")


# Load ML Models
model = load_model("Models/chatbot.h5")
words = pickle.load(open("Models/words.pkl", "rb"))
classes = pickle.load(open("Models/classes.pkl", "rb"))


# Load Dataset
with open("Dataset/chatbotdataset.json", "r", encoding="utf-8") as file:
    intents = json.load(file)

if isinstance(intents, dict):
    intents = [intents]


# Text Processing
def clean_up_sentence(sentence):
    tokens = nltk.word_tokenize(sentence)
    return [lemmatizer.lemmatize(word.lower()) for word in tokens]

def bag_of_words(sentence):
    sentence_words = clean_up_sentence(sentence)
    bag = [0] * len(words)
    for sw in sentence_words:
        for i, w in enumerate(words):
            if w == sw:
                bag[i] = 1
    return np.array(bag)


#  Prediction-
def predict_class(sentence):
    bow = bag_of_words(sentence)
    bow = pad_sequences([bow], maxlen=len(words), padding='post')
    res = model.predict(bow, verbose=0)[0]
    return classes[np.argmax(res)]


# Greeting Handler

def greeting_response(text):
    greetings = ["hi", "hello", "hey", "good morning", "good evening"]
    replies = [
        "Hi!  How can I help you today?",
        "Hello!  What would you like to practice?",
        "Hey there!  Ask me anything.",
        "Hi! I'm here to help you improve social skills."
    ]
    if text.lower() in greetings:
        return random.choice(replies)
    return None


# Response Selector
def get_response_from_intent(tag, sel_level):
    skill = tag.split("_")[0]

    # Try same skill + predicted SEL level
    for intent in intents:
        if intent["skill"] == skill:
            level_items = intent["responses"].get(sel_level.lower(), [])
            answers = []
            for item in level_items:
                answers.extend(item.get("answers", []))
            if answers:
                return random.choice(answers)

    # same skill, ANY level
    for intent in intents:
        if intent["skill"] == skill:
            answers = []
            for level_items in intent["responses"].values():
                for item in level_items:
                    answers.extend(item.get("answers", []))
            if answers:
                return random.choice(answers)

    return "Sorry, I don't understand."


# API Endpoint
@app.route("/chat", methods=["POST"])
def chat():
    data = request.json

    user_message = data.get("message", "")
    player_data = data.get("player_data", [])

    if not user_message or not player_data:
        return jsonify({"error": "message and player_data required"}), 400

    # Greeting shortcut
    greeting = greeting_response(user_message)
    if greeting:
        return jsonify({
            "sel_level": "N/A",
            "response": greeting
        })

    # Predict SEL level
    sel_level = predict_new_players([player_data])[0]

    # Predict intent
    tag = predict_class(user_message)

    # Generate response
    response = get_response_from_intent(tag, sel_level)

    return jsonify({
        "sel_level": sel_level,
        "response": response
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
