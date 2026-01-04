import json
import random
import pickle
import numpy as np
import nltk
from nltk.stem import WordNetLemmatizer
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences

from model_predict import predict_new_players   # local ML prediction

#  setup

lemmatizer = WordNetLemmatizer()
nltk.download('punkt')
nltk.download('wordnet')


# Load trained chatbot model

model = load_model("Models/chatbot.h5")
words = pickle.load(open("Models/words.pkl", "rb"))
classes = pickle.load(open("Models/classes.pkl", "rb"))


# Load chatbot dataset
with open("Dataset/chatbotdataset.json", "r", encoding="utf-8") as file:
    intents = json.load(file)

# Normalize intents structure
if isinstance(intents, dict):
    intents = [intents]


# Text preprocessing

def clean_up_sentence(sentence):
    sentence_words = nltk.word_tokenize(sentence)
    sentence_words = [lemmatizer.lemmatize(word.lower()) for word in sentence_words]
    return sentence_words


def bag_of_words(sentence):
    sentence_words = clean_up_sentence(sentence)
    bag = [0] * len(words)
    for sw in sentence_words:
        for i, w in enumerate(words):
            if w == sw:
                bag[i] = 1
    return np.array(bag)



#  prediction
def predict_class(sentence):
    bow = bag_of_words(sentence)
    bow = pad_sequences([bow], maxlen=len(words), padding='post')
    res = model.predict(bow, verbose=0)[0]
    idx = np.argmax(res)
    tag = classes[idx]
    return tag


def get_response_from_intent(tag, sel_level):

    skill_name = tag.split('_')[0]  # extract skill only

    # Try predicted SEL level responses first
    for intent in intents:
        if intent.get("skill") != skill_name:
            continue

        responses_for_level = intent.get("responses", {}).get(sel_level.lower(), [])
        all_answers = []

        for item in responses_for_level:
            all_answers.extend(item.get("answers", []))

        if all_answers:
            return random.choice(all_answers)

    # any response from same skill
    for intent in intents:
        if intent.get("skill") == skill_name:
            all_answers = []
            for level_items in intent.get("responses", {}).values():
                for item in level_items:
                    all_answers.extend(item.get("answers", []))
            if all_answers:
                return random.choice(all_answers)

    return "Sorry, I don't understand."


# MAIN CHAT FUNCTION

def chatbot_response(user_input, player_game_data):

    # Predict SEL level
    predicted_level = predict_new_players([player_game_data])[0]

    # Predict intent
    tag = predict_class(user_input)

    # Get response based on predicted SEL level
    response = get_response_from_intent(tag, predicted_level)

    return response, predicted_level


#  RUN
if __name__ == "__main__":

    # Example player data input
    player_data = [10, 1, 0, 2, 10]

    print("--> Chatbot is running (type 'quit' to exit) <--\n")

    while True:
        user_text = input("You: ")
        if user_text.lower() == "quit":
            break

        reply, sel_level = chatbot_response(user_text, player_data)
        print(f"Predicted SEL Level: {sel_level}")
        print("Bot:", reply)
        print("-" * 50)
