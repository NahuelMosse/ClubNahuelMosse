/// How many bookings each tab holds, with the same filters except the status one.
class Counters {
  const Counters({
    required this.all,
    required this.active,
    required this.completed,
    required this.voided,
  });

  final int all;
  final int active;
  final int completed;
  final int voided;
}
