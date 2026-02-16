class Account {
  late int? id;
  final String name;
  final String accNumber;
  final double available;
  final double spent;

  Account({
    this.id,
    required this.name,
    required this.accNumber,
    required this.available,
    required this.spent,
  });
}
