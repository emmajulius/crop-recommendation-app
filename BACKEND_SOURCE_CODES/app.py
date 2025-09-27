from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import os
import requests
import pandas as pd
import numpy as np
from geopy.distance import geodesic

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Load trained model
model_path = os.path.join('model_app', 'crop_recommendation_model.pkl')
if not os.path.exists(model_path):
    raise FileNotFoundError(f"Model file not found at {model_path}")
model = joblib.load(model_path)

print("✅ Model supports predict_proba:", hasattr(model, "predict_proba"))

# Load soil data CSV
soil_data_path = os.path.join('soil_data_3.csv')
if not os.path.exists(soil_data_path):
    raise FileNotFoundError(f"Soil data CSV not found at {soil_data_path}")
soil_df = pd.read_csv(soil_data_path)

# OpenWeather API Key
OPENWEATHER_API_KEY = os.getenv('OPENWEATHER_API_KEY', 'e55def8dcb235ab86fc14cad95a2c6bc')

@app.route('/', methods=['GET'])
def index():
    return jsonify({"status": "Crop Recommendation API is running 🚀"})

# Find nearest soil data point based on lat/lon
def find_nearest_soil_point(lat, lon):
    def distance(row):
        return geodesic((lat, lon), (row['latitude'], row['longitude'])).km

    soil_df['distance_km'] = soil_df.apply(distance, axis=1)
    nearest = soil_df.loc[soil_df['distance_km'].idxmin()]
    return nearest

# 🌦️ Prediction using Weather API
@app.route('/predict-weather', methods=['POST'])
def predict_crop_from_weather():
    try:
        data = request.get_json()
        if 'latitude' not in data or 'longitude' not in data:
            return jsonify({"error": "Missing latitude or longitude."}), 400

        lat = float(data['latitude'])
        lon = float(data['longitude'])
        print(f"📍 Received latitude: {lat}, longitude: {lon}")

        # Validate location limits (DSM & Pwani)
        if not (-8.0 <= lat <= -5.0 and 37.0 <= lon <= 40.0):
            return jsonify({
                "error": "No access to this location. Allowed region: DSM and Pwani (Lat -8.0 to -5.0, Lon 37.0 to 40.0)."
            }), 403

        # Fetch weather data from OpenWeatherMap
        weather_url = (
            f"https://api.openweathermap.org/data/2.5/weather"
            f"?lat={lat}&lon={lon}&units=metric&appid={OPENWEATHER_API_KEY}"
        )
        response = requests.get(weather_url)
        print(f"🌦️ OpenWeather API response status: {response.status_code}")

        if response.status_code != 200:
            return jsonify({"error": "Failed to fetch weather data.", "details": response.text}), 500

        weather_data = response.json()
        temperature = weather_data['main']['temp']
        humidity = weather_data['main']['humidity']
        rainfall = weather_data.get('rain', {}).get('1h', 0)

        # Get nearest soil data
        soil_values = find_nearest_soil_point(lat, lon)
        print(f"🧭 Nearest soil data found:\n{soil_values}")

        input_data = [[
            float(soil_values['N']),
            float(soil_values['P']),
            float(soil_values['K']),
            float(temperature),
            float(humidity),
            float(soil_values['ph']),
            rainfall
        ]]
        print("📝 Model input data:\n", pd.DataFrame(input_data, columns=['N','P','K','temperature','humidity','ph','rainfall']))

        if hasattr(model, "predict_proba"):
            probs = model.predict_proba(input_data)[0]
            classes = model.classes_
            top3_idx = np.argsort(probs)[::-1][:3]
            top3_crops = [{"crop": classes[i], "probability": float(probs[i])} for i in top3_idx]

            return jsonify({
                "recommended_crops": top3_crops,
                "temperature": float(temperature),
                "humidity": int(humidity),
                "rainfall": float(rainfall),
                "soil_region": soil_values['region'],
                "soil_sub_region": soil_values['sub_region'],
                "soil_N": int(soil_values['N']),
                "soil_P": int(soil_values['P']),
                "soil_K": int(soil_values['K']),
                "soil_ph": float(soil_values['ph']),
                "nearest_soil_distance_km": float(soil_values['distance_km']),
                "soil_latitude": float(soil_values['latitude']),
                "soil_longitude": float(soil_values['longitude']),
                "polygon": soil_values['polygon']
            })

        else:
            prediction = model.predict(input_data)
            return jsonify({
                "recommended_crop": prediction[0],
                "temperature": float(temperature),
                "humidity": int(humidity),
                "rainfall": float(rainfall)
            })

    except Exception as e:
        print("❌ Error in /predict-weather:", e)
        return jsonify({"error": str(e)}), 500

# 📝 Prediction using manual data input
@app.route('/predict', methods=['POST'])
def predict_crop_from_manual_input():
    try:
        data = request.get_json()
        required_fields = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']

        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400

        input_data = [[
            float(data['N']),
            float(data['P']),
            float(data['K']),
            float(data['temperature']),
            float(data['humidity']),
            float(data['ph']),
            float(data['rainfall'])
        ]]
        print("📝 Manual input data:\n", input_data)

        if hasattr(model, "predict_proba"):
            probs = model.predict_proba(input_data)[0]
            classes = model.classes_
            top3_idx = np.argsort(probs)[::-1][:3]
            top3_crops = [{"crop": classes[i], "probability": float(probs[i])} for i in top3_idx]

            return jsonify({"recommended_crops": top3_crops})

        else:
            prediction = model.predict(input_data)
            return jsonify({"recommended_crop": prediction[0]})

    except Exception as e:
        print("❌ Error in /predict:", e)
        return jsonify({"error": str(e)}), 500

# Run the API
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
