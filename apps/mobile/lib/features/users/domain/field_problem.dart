/// What a registration or profile rule found wrong with a value. The screen shows the text
/// for each one in the language of the device.
enum FieldProblem {
  nameRequired,
  nameTooLong,
  dniRequired,
  dniFormat,
  birthRequired,
  birthInvalid,
  birthNotPast,
  emailRequired,
  emailFormat,
  passwordRequired,
  passwordLength,
  passwordUppercase,
  passwordNumber,
}
