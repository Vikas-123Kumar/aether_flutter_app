import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WeatherForecastScreen();
}

class _WeatherForecastScreen extends State<WeatherForecastScreen> {
  List<dynamic> weatherList = [];
  bool isLoading = false;
  String error = "";
  String location = "";
  String timezone = "";
  @override
  void initState() {
    super.initState();
    getWeatherForecast();
  }

  Future<void> getWeatherForecast() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      String token = prefs.getString("token") ?? "";

      final response = await http.get(
        Uri.parse(
          "https://aetherone.com.au/api/v1/next8DaysWeather",
        ),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          json["success"] == true) {
        setState(() {
          weatherList = json["data"];

          location = json["location"]["name"];

          timezone = json["timezone"];

          isLoading = false;
        });
      } else {
        setState(() {
          error = json["message"];

          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();

        isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff091426),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Weather Forecast",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : error.isNotEmpty
          ? Center(
        child: Text(error),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            buildHeroCard(),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "8 Day Forecast",
                style: TextStyle(
                  color: Colors.white.withOpacity(.85),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),


            /// FORECAST CARD
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weatherList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return buildForecastCard(weatherList[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget buildForecastCard(dynamic weather) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(.05),
        border: Border.all(
          color: Colors.white.withOpacity(.08),
        ),
      ),
      child: Row(
        children: [

          /// Weather Icon
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                getWeatherEmoji(weather["condition"]),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),

          const SizedBox(width: 16),

          /// Center
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  formatDate(weather["date"]),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  weather["condition"].toString().toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(.65),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [

                    miniChip(
                      Icons.water_drop,
                      "${weather["precipitation_probability_max"]}%",
                      Colors.blue,
                    ),

                    const SizedBox(width: 10),

                    miniChip(
                      Icons.air,
                      "${weather["wind_gusts_10m_max"]}",
                      Colors.green,
                    ),
                  ],
                )
              ],
            ),
          ),

          /// Alert Badge
          if (weather["is_bad_weather"] == true)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                "Alert",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget miniChip(
      IconData icon,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Icon(
            icon,
            color: color,
            size: 15,
          ),

          const SizedBox(width: 5),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }
  String formatDate(String date) {
    final d = DateTime.parse(date);

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];

    const weekdays = [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun"
    ];

    return "${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}";
  }

  Widget buildHeroCard() {
    if (weatherList.isEmpty) return const SizedBox();

    final today = weatherList[0];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff29406F),
            Color(0xff18294A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [

          Text(
            getWeatherEmoji(today["condition"]),
            style: const TextStyle(fontSize: 70),
          ),
          const SizedBox(height: 12),
          Text(
            today["condition"].toString().toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            location,
            style: TextStyle(
              color: Colors.white.withOpacity(.8),
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              buildChip(
                Icons.water_drop,
                "${today["precipitation_probability_max"]}%",
                "Rain",
              ),

              buildChip(
                Icons.grain,
                "${today["precipitation_sum"]} mm",
                "Rainfall",
              ),

              buildChip(
                Icons.air,
                "${today["wind_gusts_10m_max"]}",
                "Wind",
              ),
            ],
          ),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    today["summary"],
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
  Widget buildChip(IconData icon, String value, String title) {
    return Column(
      children: [

        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.lightBlueAccent,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),

        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  String getWeatherEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case "stormy":
        return "⛈️";

      case "drizzle":
        return "🌦️";

      case "light drizzle":
        return "🌦️";

      case "rain":
        return "🌧️";

      case "sunny":
        return "☀️";

      case "cloudy":
        return "☁️";

      default:
        return "🌤️";
    }
  }
  Widget _info(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'stormy':
        return Icons.thunderstorm;

      case 'drizzle':
      case 'light drizzle':
        return Icons.grain;

      case 'rain':
        return Icons.umbrella;

      case 'cloudy':
        return Icons.cloud;

      case 'clear':
      case 'sunny':
        return Icons.wb_sunny;

      default:
        return Icons.cloud;
    }
  }
}
