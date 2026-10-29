/// Las opciones de «DÍAS QUE ABRE» del alta de sede; el texto de cada una sale de las
/// traducciones.
enum OpenDays {
  mondayToSunday([1, 2, 3, 4, 5, 6, 7]),
  mondayToSaturday([1, 2, 3, 4, 5, 6]),
  mondayToFriday([1, 2, 3, 4, 5]);

  const OpenDays(this.days);
  final List<int> days;
}
