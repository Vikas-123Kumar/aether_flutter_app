class WeatherForecast {
  final String date;
  final int weatherCode;
  final String condition;
  final bool isBadWeather;
  final String summary;
  final int precipitationProbabilityMax;
  final double precipitationSum;
  final double windGusts10mMax;

  WeatherForecast({
    required this.date,
    required this.weatherCode,
    required this.condition,
    required this.isBadWeather,
    required this.summary,
    required this.precipitationProbabilityMax,
    required this.precipitationSum,
    required this.windGusts10mMax,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: json['date'],
      weatherCode: json['weather_code'],
      condition: json['condition'],
      isBadWeather: json['is_bad_weather'],
      summary: json['summary'],
      precipitationProbabilityMax: json['precipitation_probability_max'],
      precipitationSum:
      (json['precipitation_sum'] as num).toDouble(),
      windGusts10mMax:
      (json['wind_gusts_10m_max'] as num).toDouble(),
    );
  }
}