# Weather API Setup

To enable real weather data in XcelGolf, you need to set up an OpenWeatherMap API key.

## Steps:

1. **Get a Free API Key:**
   - Go to [OpenWeatherMap](https://openweathermap.org/api)
   - Sign up for a free account
   - Go to your API keys section
   - Copy your API key

2. **Add the API Key to the App:**
   - Open `XcelGolf/Services/WeatherManager.swift`
   - Find the line: `private let apiKey = "YOUR_API_KEY_HERE"`
   - Replace `"YOUR_API_KEY_HERE"` with your actual API key

3. **Example:**
   ```swift
   private let apiKey = "abcd1234efgh5678ijkl9012mnop3456"
   ```

## Features Enabled:
- Real-time temperature
- Current weather conditions (sunny, cloudy, rainy, etc.)
- Wind speed and direction
- Weather-appropriate icons and colors

## Fallback Behavior:
If no API key is configured, the app will show default values:
- Temperature: 72°F
- Wind: 5 mph NE
- Icon: Sunny

## API Limits:
- Free tier: 1,000 calls per day
- App fetches weather only when location changes
- Minimal API usage for battery and data efficiency 