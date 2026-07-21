import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ==================== MODEL ====================
class WeatherNotification {
  final int id;
  final String title;
  final String body;
  final String locationLabel;
  final String forecastDate;
  final int weatherCode;
  final double precipitationProbability;
  final double precipitationSum;
  final double windGusts;
  final String sentAt;
  bool isRead;

  WeatherNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.locationLabel,
    required this.forecastDate,
    required this.weatherCode,
    required this.precipitationProbability,
    required this.precipitationSum,
    required this.windGusts,
    required this.sentAt,
    required this.isRead,
  });

  factory WeatherNotification.fromJson(Map<String, dynamic> json) {
    return WeatherNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      locationLabel: json['location_label'] ?? '',
      forecastDate: json['forecast_date'] ?? '',
      weatherCode: json['weather_code'] ?? 0,
      precipitationProbability:
          (json['precipitation_probability_max'] as num?)?.toDouble() ?? 0.0,
      precipitationSum: (json['precipitation_sum'] as num?)?.toDouble() ?? 0.0,
      windGusts: (json['wind_gusts_10m_max'] as num?)?.toDouble() ?? 0.0,
      sentAt: json['sent_at'] ?? '',
      isRead: json['is_read'] ?? false,
    );
  }
}

// ==================== SCREEN ====================
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<WeatherNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications(status: "sent", readStatus: "unread");
  }

  Future<void> _fetchNotifications({
    int page = 1,
    int perPage = 20,
    String? status,
    String? readStatus,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final uri = Uri.https('aetherone.com.au', '/api/v1/notifications', {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (status != null) 'status': status,
        if (readStatus != null) 'read_status': readStatus,
      });

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> dataList = responseData['data'] ?? [];
          print(dataList);
          setState(() {
            _notifications = dataList
                .map((item) => WeatherNotification.fromJson(item))
                .toList();

            _unreadCount =
                responseData['unread_count'] ??
                _notifications.where((n) => !n.isRead).length;

            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Failed to load notifications';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Unable to connect to server. Please check your internet connection.';
        _isLoading = false;
      });
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
      _unreadCount = 0;
    });
    // Optional: Call API to mark all as read on backend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C101B),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
           /* if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]*/
          ],
        ),
        actions: [
          if (_unreadCount > 0 && !_isLoading && _notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // --- DYNAMIC BODY STATE HANDLER ---
  Widget _buildBody() {
    // 1. Loading State
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Error State
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Empty State ("No Notifications")
    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Notifications Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "We'll inform you when there are new weather updates.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 4. Data State (List View)
    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return _NotificationCard(
            notification: item,
            onTap: () {
              setState(() {
                if (!item.isRead) {
                  item.isRead = true;
                  if (_unreadCount > 0) _unreadCount--;
                }
              });
            },
          );
        },
      ),
    );
  }
}

// ==================== CARD WIDGET ====================
class _NotificationCard extends StatelessWidget {
  final WeatherNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  IconData _getWeatherIcon(int code) {
    if (code >= 60 && code <= 69) return Icons.water_drop_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    if (code >= 70 && code <= 79) return Icons.ac_unit_rounded;
    if (code >= 1 && code <= 3) return Icons.cloud_rounded;
    return Icons.wb_sunny_rounded;
  }

  Color _getWeatherColor(int code) {
    if (code >= 60 && code <= 69) return Colors.blue.shade600;
    if (code >= 95) return Colors.purple.shade600;
    if (code >= 1 && code <= 3) return Colors.blueGrey.shade600;
    return Colors.amber.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getWeatherColor(notification.weatherCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.shade200
              : Colors.blue.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getWeatherIcon(notification.weatherCode),
                      color: themeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${notification.locationLabel} • ${notification.forecastDate}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MetricBadge(
                    icon: Icons.umbrella_outlined,
                    label:
                        '${notification.precipitationProbability.toInt()}% rain',
                  ),
                  _MetricBadge(
                    icon: Icons.air_rounded,
                    label: '${notification.windGusts} km/h wind',
                  ),
                  _MetricBadge(
                    icon: Icons.water_drop_outlined,
                    label: '${notification.precipitationSum} mm',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== BADGE HELPER ====================
class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricBadge({Key? key, required this.icon, required this.label})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
