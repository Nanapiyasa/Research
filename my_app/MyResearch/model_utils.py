import joblib
from path_utils import check_path_exists
from config import Config


# Load the trained  model
def load_model():

    check_path_exists(Config.MODEL_PATH, "Trained Model")
    model = joblib.load(Config.MODEL_PATH)
    print("-- Model loaded successfully.")
    return model

# Load the LabelEncoder
def load_encoder():

    check_path_exists(Config.ENCODER_PATH, "Label Encoder")
    encoder = joblib.load(Config.ENCODER_PATH)
    print("-- Encoder loaded successfully.")
    return encoder

def load_model_and_encoder():
    return load_model(), load_encoder()
