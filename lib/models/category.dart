class Category {
  late int? id;
  final String color;
  final String name;

  Category({this.id, required this.color, required this.name});

  @override
  String toString() {
    return name;
  }
}
