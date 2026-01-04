import serial
import time
import threading
import traceback
import sys
import pandas as pd
from collections import deque
import re
from data_loader import load_dataset
from model_utils import load_model_and_encoder

class SerialMonitor:
    def __init__(self):
        self.port = "COM3"
        self.baudrate = 115200
        self.ser = None
        self.running = False
        self.prediction_made = False  
        
        # Heart rate monitoring variables
        self.heart_rate_history = deque(maxlen=25)  
        
        # User Input
        self.user_profile = {
            "Age": 8,
            "Weight": 12,
            "Height": 52,
            "Memory_Score": 20,
            "Reaction_Time": 100
        }
        
        # Debug 
        self.line_count = 0
        
        # Load model 
        print("Loading model and encoder...")
        try:
            self.model, self.encoder = load_model_and_encoder()
            self.dataset = load_dataset()
            print("Model and dataset loaded successfully!")
        except Exception as e:
            print(f"Error loading model: {e}")
            print("Please make sure data_loader.py and model_utils.py are in the same directory")
            print("or install the required packages.")
            self.model = None
            self.encoder = None
            self.dataset = None

    def connect(self):
        print("---INITIALIZATION---")
        print(f"Connected  : {self.port}")
        print(f"⚙ Using Sensor BAUD : {self.baudrate}")

        try:
            self.ser = serial.Serial(self.port, self.baudrate, timeout=1)
            self.running = True
            print(f"Connected to {self.port} successfully\n")
            print("Waiting for serial data...\n")
        except Exception as e:
            print("ERROR: Cannot open serial port!")
            traceback.print_exc()
            sys.exit(1)

    def start(self):
        print("Starting Serial Listener Thread...\n")
        thread = threading.Thread(target=self.read_loop, daemon=True)
        thread.start()

        try:
            while self.running and not self.prediction_made:
                time.sleep(0.2)
            
            # Wait a bit for thread to finish
            time.sleep(1)
            
            if self.prediction_made:
                print("\n" + "="*60)
                print("="*60)
                time.sleep(3)  
                
        except KeyboardInterrupt:
            print("\nStopping Serial Monitor...")
            self.running = False
        finally:
            self.stop_monitoring()

    def stop_monitoring(self):
        self.running = False
        if self.ser and self.ser.is_open:
            self.ser.close()
            print("Serial port closed.")

    def extract_heart_rate(self, text):
        try:
            numbers = re.findall(r'\b\d+\b', text)
            
            if numbers:
               
                for num_str in numbers:
                    num = float(num_str)
                    if 20 <= num <= 250:
                        print(f"DEBUG: Found heart rate: {num} BPM")
                        return num
            
            return None
            
        except Exception as e:
            return None

    def monitor_heart_rate(self, heart_rate):
     
        if heart_rate is None or self.prediction_made:
            return
            
 
        current_time = time.time()
        self.heart_rate_history.append((current_time, heart_rate))
        
        print(f"HR Monitor: Current={heart_rate} BPM, History length={len(self.heart_rate_history)}")
        

        if len(self.heart_rate_history) >= 25:  

            all_hr_values = [hr for _, hr in self.heart_rate_history]
            

            all_positive = all(hr > 0 for hr in all_hr_values)
            
            print(f"HR Monitor: All positive={all_positive}")
            
            if all_positive and not self.prediction_made:
                print("\n" + "="*60)
                print("--> TRIGGERING PREDICTION - Heart rate > 0 for 5 seconds")
                print(f"--> Heart Rate History: {all_hr_values}")
                print("="*60)
                
                # Make prediction (this will set prediction_made to True)
                self.make_prediction(heart_rate)

    def make_prediction(self, current_heart_rate):
 
        if self.model is None or self.encoder is None:
            print("--> Model not loaded. Cannot make prediction.")
            return
            
        try:
 
            sample_input = self.user_profile.copy()
            sample_input["Heart_Rate"] = current_heart_rate
            
            print("\n--- User Profile ---")
            for k, v in sample_input.items():
                print(f"{k}: {v}")
            
            # Prepare input for model
            features = ["Age", "Weight", "Height", "Memory_Score", "Reaction_Time", "Heart_Rate"]
            X_sample = pd.DataFrame([sample_input])[features]
            
            print(f"\n--> Making prediction with features:")
            print(X_sample)
            
            # Predict
            pred_encoded = self.model.predict(X_sample)
            predicted_level = self.encoder.inverse_transform(pred_encoded)[0]
            
            # Get recommendation
            matching_row = self.dataset[
                (self.dataset["Age"] == sample_input["Age"]) &
                (self.dataset["Weight"] == sample_input["Weight"]) &
                (self.dataset["Height"] == sample_input["Height"])
            ]
            
            if not matching_row.empty:
                recommendation = matching_row.iloc[0]["Recommendation"]
            else:
                recommendation_rows = self.dataset[self.dataset["Down_Syndrome_Level"] == predicted_level]
                if not recommendation_rows.empty:
                    recommendation = recommendation_rows.sample(1).iloc[0]["Recommendation"]
                else:
                    recommendation = "No specific recommendation available."
            
 
            print("\n" + "="*60)
            print("--> PREDICTION RESULTS")
            print("="*60)
            print(f"--> Predicted Down Syndrome Level: {predicted_level}")
            print(f"--> Recommendation: {recommendation}")
            print(f"-->  Current Heart Rate: {current_heart_rate} BPM")
            print("="*60 + "\n")
            
            # Set flag to stop monitoring
            self.prediction_made = True
            self.running = False
            
            # Clear history
            self.heart_rate_history.clear()
            
        except Exception as e:
            print(f"--> Error during prediction: {e}")
            traceback.print_exc()

    def read_loop(self):
         
        while self.running and not self.prediction_made:
            try:
                raw = self.ser.readline()
                
                if raw and not self.prediction_made:
                    self.line_count += 1
                    
                    try:
                        text = raw.decode('utf-8').strip()
                    except UnicodeDecodeError:
                        text = raw.decode(errors="ignore").strip()
                    
    
                    if not text:
                        continue
                    
                    timestamp = time.strftime("%H:%M:%S")
                    
                    print(f"\n[{timestamp}] Line #{self.line_count}")
                    print(f"--> Decoded: '{text}'")
                    
                   
                    heart_rate = self.extract_heart_rate(text)
                    
                    if heart_rate is not None and not self.prediction_made:
                        print(f"-->  Heart Rate Detected: {heart_rate} BPM")
                        self.monitor_heart_rate(heart_rate)
                    
                    print("-" * 40)
                    
            except Exception as e:
                if not self.prediction_made:
                    print(f"--> Serial Read Error: {e}")
                    traceback.print_exc()
                    time.sleep(0.5)
        
        print("Serial reading loop stopped.")

if __name__ == "__main__":
    monitor = SerialMonitor()
    monitor.connect()
    
  
    print("\n" + "="*60)
    print("--> Serial Monitor Started")
    print("="*60)
    print("Monitoring for heart rate data...")
    print("="*60 + "\n")
    
    monitor.start()