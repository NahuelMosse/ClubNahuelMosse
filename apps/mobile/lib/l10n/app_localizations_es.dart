// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Club Nahuel Mosse';

  @override
  String get accountTitle => 'Tu cuenta';

  @override
  String get accountCloseCard => 'Cerrar la tarjeta de tu cuenta';

  @override
  String get accountActiveMember => 'MIEMBRO ACTIVO';

  @override
  String get accountFullProfile => 'Perfil completo';

  @override
  String get accountMyBookings => 'Mis reservas';

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get accountSignOutUpper => 'CERRAR SESIÓN';

  @override
  String get accountDeleteUpper => 'ELIMINAR CUENTA';

  @override
  String get accountDeleting => 'ELIMINANDO TU CUENTA…';

  @override
  String get accountCancel => 'CANCELAR';

  @override
  String get accountBackToSignIn => 'VOLVER AL INICIO DE SESIÓN';

  @override
  String get accessDeniedTitle => 'Acceso denegado';

  @override
  String get accessDeniedBody =>
      'Tu cuenta no tiene permisos de administrador. Te llevamos a Mis reservas.';

  @override
  String get accessDeniedGoToBookings => 'IR A MIS RESERVAS';

  @override
  String get recoveryTitle => 'Recuperar contraseña';

  @override
  String get recoveryIntro =>
      'Ingresá el correo con el que te registraste y te enviamos un enlace para crear una nueva.';

  @override
  String get recoverySend => 'ENVIAR ENLACE';

  @override
  String get recoveryCheckEmail => 'Revisá tu correo';

  @override
  String get recoveryLinkSent =>
      'Si el correo está registrado, te enviamos un enlace para crear una contraseña nueva. El enlace vence en 30 minutos.';

  @override
  String get recoveryResend => 'Reenviar el correo';

  @override
  String get newPasswordChecking => 'Comprobando el enlace';

  @override
  String get newPasswordInvalidTitle => 'El enlace no es válido';

  @override
  String get newPasswordInvalidAfterCutoff =>
      'Este enlace ya se usó o venció. Si recién guardaste tu contraseña nueva, iniciá sesión con ella.';

  @override
  String get newPasswordInvalid =>
      'Este enlace ya se usó o venció. Pedí uno nuevo desde la pantalla de inicio de sesión.';

  @override
  String get newPasswordRequestNew => 'PEDIR UN ENLACE NUEVO';

  @override
  String get newPasswordBackToSignIn => 'Volver al inicio de sesión';

  @override
  String get newPasswordBarTitle => 'Nueva contraseña';

  @override
  String get newPasswordHeading => 'Creá una contraseña nueva';

  @override
  String get newPasswordExplanation =>
      'Tiene que tener al menos 8 caracteres, una mayúscula y un número.';

  @override
  String get changePasswordTitle => 'Cambiar contraseña';

  @override
  String get changePasswordHeading => 'Cambiá tu contraseña';

  @override
  String get changePasswordExplanation =>
      'Necesitamos tu contraseña actual para confirmar que sos vos.';

  @override
  String get changePasswordBack => 'VOLVER AL PERFIL';

  @override
  String get passwordCurrentUpper => 'CONTRASEÑA ACTUAL';

  @override
  String get passwordCurrent => 'Contraseña actual';

  @override
  String get passwordCurrentPlaceholder => 'Tu contraseña de hoy';

  @override
  String get passwordNewUpper => 'CONTRASEÑA NUEVA';

  @override
  String get passwordNew => 'Contraseña nueva';

  @override
  String get passwordNewPlaceholder => 'Mínimo 8 caracteres';

  @override
  String get passwordRepeatUpper => 'REPETIR CONTRASEÑA';

  @override
  String get passwordRepeat => 'Repetir contraseña';

  @override
  String get passwordRepeatPlaceholder => 'Volvé a escribirla';

  @override
  String passwordRuleMet(Object rule) {
    return '$rule: cumplida';
  }

  @override
  String passwordRuleMissing(Object rule) {
    return '$rule: falta';
  }

  @override
  String get registerTitle => 'Registro';

  @override
  String get registerHeading => 'Creá tu cuenta';

  @override
  String get registerAllRequired => 'Todos los campos son obligatorios.';

  @override
  String get registerAlreadyExists =>
      'Tu cuenta ya existe: el registro se completó antes del corte. Iniciá sesión con tu correo y tu contraseña.';

  @override
  String get registerFirstNamePlaceholder => 'Tu nombre';

  @override
  String get registerLastNamePlaceholder => 'Tu apellido';

  @override
  String get registerBirthPlaceholder => 'DD / MM / AAAA';

  @override
  String get registerPickDate => 'Elegir fecha';

  @override
  String get registerPasswordPlaceholder => '8+ caracteres, mayúscula y número';

  @override
  String get registerCreate => 'CREAR CUENTA';

  @override
  String get registerDoneTitle => '¡Cuenta creada!';

  @override
  String get registerDoneText =>
      'Tu cuenta se registró con éxito. Ya podés iniciar sesión con tu correo y contraseña.';

  @override
  String get profileFirstNameUpper => 'NOMBRE';

  @override
  String get profileFirstName => 'Nombre';

  @override
  String get profileLastNameUpper => 'APELLIDO';

  @override
  String get profileLastName => 'Apellido';

  @override
  String get profileDni => 'DNI';

  @override
  String get profileBirthUpper => 'FECHA DE NACIMIENTO';

  @override
  String get profileBirth => 'Fecha de nacimiento';

  @override
  String get profileBirthShort => 'Nacimiento';

  @override
  String get profileEmailUpper => 'CORREO ELECTRÓNICO';

  @override
  String get profileEmail => 'Correo electrónico';

  @override
  String get profileEmailShort => 'Correo';

  @override
  String get profileEmailPlaceholder => 'tu@correo.com';

  @override
  String get profilePasswordUpper => 'CONTRASEÑA';

  @override
  String get profilePassword => 'Contraseña';

  @override
  String profileFixedField(Object label, Object value) {
    return '$label: $value. No se puede cambiar';
  }

  @override
  String get profilePersonalUpper => 'DATOS PERSONALES';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileSecurityUpper => 'SEGURIDAD';

  @override
  String get profileAppearanceUpper => 'APARIENCIA';

  @override
  String get profileDarkMode => 'Modo oscuro';

  @override
  String get profileInvalidData => 'El formato de los datos no es válido';

  @override
  String get profilePickDate => 'Elegir la fecha en el calendario';

  @override
  String get profileSave => 'GUARDAR';

  @override
  String get profileDeleteTitle => '¿Eliminar tu cuenta?';

  @override
  String get profileDeleteBody =>
      'Esta acción es permanente. Se eliminarán tus datos y tus reservas vigentes.';

  @override
  String get ruleFirstNameRequired => 'El nombre es obligatorio';

  @override
  String get ruleLastNameRequired => 'El apellido es obligatorio';

  @override
  String ruleNameTooLong(int max) {
    return 'Máximo $max caracteres';
  }

  @override
  String get ruleDniRequired => 'El DNI es obligatorio';

  @override
  String get ruleDniFormat => 'El DNI tiene 7 u 8 números';

  @override
  String get ruleBirthRequired => 'La fecha de nacimiento es obligatoria';

  @override
  String get ruleBirthInvalid => 'La fecha no es válida';

  @override
  String get ruleBirthNotPast => 'La fecha tiene que ser anterior a hoy';

  @override
  String get ruleEmailRequired => 'El correo es obligatorio';

  @override
  String get ruleEmailFormat => 'Revisá el formato del correo';

  @override
  String get rulePasswordRequired => 'La contraseña es obligatoria';

  @override
  String get rulePasswordLength => 'Al menos 8 caracteres';

  @override
  String get rulePasswordUppercase => 'Una letra mayúscula';

  @override
  String get rulePasswordNumber => 'Al menos un número';

  @override
  String get rulePasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get homeGreetingMorning => 'BUENOS DÍAS,';

  @override
  String get homeGreetingAfternoon => 'BUENAS TARDES,';

  @override
  String get homeGreetingNight => 'BUENAS NOCHES,';

  @override
  String get homeHeroTitle => 'RESERVÁ TU CANCHA';

  @override
  String get homeMarkerVenues => 'SEDES';

  @override
  String get homeMarkerCourts => 'CANCHAS';

  @override
  String get homeMarkerUpcoming => 'PRÓXIMAS';

  @override
  String get homeQuickAccess => 'ACCESOS RÁPIDOS';

  @override
  String get homeSports => 'DEPORTES';

  @override
  String get homeFindCourt => 'Buscar cancha';

  @override
  String get homeFindCourtHint => 'Por sede, fecha y horario';

  @override
  String get homeViewVenues => 'Ver sedes';

  @override
  String get homeViewVenuesHint => 'Horarios y canchas de cada una';

  @override
  String get homeNextBooking => 'TU PRÓXIMA RESERVA';

  @override
  String get homeViewAll => 'VER TODAS →';

  @override
  String get homeBackLabel => 'Inicio';

  @override
  String get loginWelcome => 'BIENVENIDO A';

  @override
  String get loginTagline => 'Gestión de espacios deportivos';

  @override
  String get loginEmailLabel => 'Correo';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginNoAccount => '¿No tenés cuenta?';

  @override
  String get loginStart => 'COMENZAR';

  @override
  String get loginSignIn => 'INICIAR SESIÓN';

  @override
  String get loginEmailRequired => 'Completá tu correo electrónico';

  @override
  String get loginPasswordRequired => 'Completá tu contraseña';

  @override
  String get loginInvalidCredentials =>
      'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.';
}
