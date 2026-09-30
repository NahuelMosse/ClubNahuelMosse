import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../tema/tokens.dart';
import 'dialogo_error.dart';

/// Adonde cae un usuario que pidió una sección de administrador: el aviso compartido y,
/// al aceptarlo, Mis reservas.
class PantallaAccesoDenegado extends StatefulWidget {
  const PantallaAccesoDenegado({super.key});

  @override
  State<PantallaAccesoDenegado> createState() => _PantallaAccesoDenegadoState();
}

class _PantallaAccesoDenegadoState extends State<PantallaAccesoDenegado> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _avisar());
  }

  Future<void> _avisar() async {
    if (!mounted) return;
    await mostrarAccesoDenegado(context);
    if (mounted) context.go('/reservas');
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: context.paleta.bgBase);
}
