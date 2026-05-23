class AlertModel {
  final String title;
  final String description;
  final String type; // critical / warning
  final String time;

  AlertModel({
    required this.title,
    required this.description,
    required this.type,
    required this.time,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      title: json['title'],
      description: json['description'],
      type: json['type'],
      time: json['time'],
    );
  }
}