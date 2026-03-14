class HeatmapData {
  final String hour;
  final int day;
  final int orders;
  final double rating;

  HeatmapData({
    required this.hour,
    required this.day,
    required this.orders,
    required this.rating,
  });

  static int dayToNumber(String day) {
    switch (day) {
      case "Monday":
        return 1;
      case "Tuesday":
        return 2;
      case "Wednesday":
        return 3;
      case "Thursday":
        return 4;
      case "Friday":
        return 5;
      case "Saturday":
        return 6;
      case "Sunday":
        return 7;
      default:
        return 0;
    }
  }
}
