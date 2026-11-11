/// The options of «DÍAS QUE ABRE» of the venue creation; the text of each comes from the
/// translations.
enum OpenDays {
  mondayToSunday([1, 2, 3, 4, 5, 6, 7]),
  mondayToSaturday([1, 2, 3, 4, 5, 6]),
  mondayToFriday([1, 2, 3, 4, 5]);

  const OpenDays(this.days);
  final List<int> days;
}
