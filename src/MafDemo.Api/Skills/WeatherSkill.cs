using Microsoft.Agents.AI;
using System.ComponentModel;
using System.Text.Json.Serialization;

namespace MafDemo.Api.Skills;

/// <summary>
/// Weather lookup skill - demonstrates a tool that:
/// - Takes structured parameters (validated)
/// - Returns structured responses
/// - Includes descriptive metadata for the agent
/// 
/// This is a demo skill that simulates weather API calls.
/// Real implementation would call an actual weather service.
/// </summary>
public class WeatherSkill
{
    /// <summary>
    /// Parameters for weather lookup
    /// </summary>
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public class GetWeatherInput
    {
        [Description("City name (e.g., 'London', 'Sydney', 'New York')")]
        [JsonPropertyName("city")]
        public string City { get; set; } = string.Empty;

        [Description("Temperature unit: 'celsius' or 'fahrenheit' (default: celsius)")]
        [JsonPropertyName("unit")]
        public string Unit { get; set; } = "celsius";
    }

    /// <summary>
    /// Weather response model
    /// </summary>
    public class WeatherResponse
    {
        [JsonPropertyName("city")]
        public string City { get; set; } = string.Empty;

        [JsonPropertyName("temperature")]
        public float Temperature { get; set; }

        [JsonPropertyName("condition")]
        public string Condition { get; set; } = string.Empty;

        [JsonPropertyName("humidity")]
        public int Humidity { get; set; }

        [JsonPropertyName("unit")]
        public string Unit { get; set; } = string.Empty;
    }

    /// <summary>
    /// Get current weather for a city (demo implementation)
    /// </summary>
    /// <remarks>
    /// This is a demonstration tool. In production, this would call a real weather API.
    /// The model will use this to answer weather-related queries.
    /// </remarks>
    public static WeatherResponse GetWeather(GetWeatherInput input)
    {
        // Validate inputs (as per safety requirement: treat tool inputs as untrusted)
        if (string.IsNullOrWhiteSpace(input.City))
        {
            throw new ArgumentException("City name cannot be empty", nameof(input.City));
        }

        var unit = (input.Unit ?? "celsius").ToLowerInvariant();
        if (unit != "celsius" && unit != "fahrenheit")
        {
            throw new ArgumentException("Unit must be 'celsius' or 'fahrenheit'", nameof(input.Unit));
        }

        // Demo: Return mock data based on city
        // Real implementation would call weather API
        var (temp, condition, humidity) = input.City.ToLowerInvariant() switch
        {
            "sydney" => (22, "Partly Cloudy", 65),
            "london" => (15, "Rainy", 80),
            "new york" => (18, "Cloudy", 70),
            "tokyo" => (25, "Sunny", 60),
            _ => (20, "Unknown", 50), // Default for unknown cities
        };

        // Convert to requested unit if needed
        if (unit == "fahrenheit")
        {
            temp = (int)((temp * 9 / 5) + 32);
        }

        return new WeatherResponse
        {
            City = input.City,
            Temperature = temp,
            Condition = condition,
            Humidity = humidity,
            Unit = unit,
        };
    }

    /// <summary>
    /// Create the Weather tool for use in the agent
    /// </summary>
    public static AITool CreateTool()
    {
        return AIFunctionFactory.Create(
            name: "get_weather",
            description: "Get current weather information for a city. Useful when the user asks about weather conditions, temperature, or climate.",
            function: GetWeather,
            parameters: typeof(GetWeatherInput)
        );
    }
}
