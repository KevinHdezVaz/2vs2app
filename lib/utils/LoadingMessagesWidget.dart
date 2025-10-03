import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingMessagesWidget extends StatefulWidget {
  const LoadingMessagesWidget({Key? key}) : super(key: key);

  @override
  State<LoadingMessagesWidget> createState() => _LoadingMessagesWidgetState();
}

class _LoadingMessagesWidgetState extends State<LoadingMessagesWidget> {
  // Lista de mensajes que quieres mostrar
  static const List<String> _messages = [
    // Mensajes Originales (con coma corregida)
    'Analizando tus respuestas...',
    'Creando un plan único para ti...',
    'Frutia está aquí para acompañarte.',
    'Ya casi queda tu plan perfecto.',
    'Frutia sabe lo que necesitas en todo momento.',
    'Más de mil usuarios confían en nosotros.',
    'Estamos seleccionando las mejores recetas...',
    '¡Prepárate para un cambio positivo!',

    // Nuevos Mensajes
    'Calculando tus macros y calorías...',
    'Ajustando las porciones a tu medida.',
    'Filtrando recetas según tus gustos y alergias...',
    'Nuestra inteligencia artificial trabaja para ti.',
    'Estás invirtiendo en tu salud. ¡Bien hecho!',
    'Estructurando tus comidas para el éxito.',
    'La constancia es la clave, y estamos para ayudarte.',
    'Compilando tu lista de compras inteligente...',
    'Comer rico y saludable es posible.',
    'Imagina la energía que tendrás.',
    'Tu viaje hacia una mejor versión de ti comienza ahora.',
    'Nos tomamos tu bienestar muy en serio.',
    'Un pequeño paso para ti, un gran salto para tu salud.',
    'La paciencia es un ingrediente secreto.',
    'Optimizando el plan para tu presupuesto.',
  ];

  int _currentIndex = 0;
  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    // Creamos un "ticker" que emite un nuevo valor cada 3 segundos
    // y actualiza el índice del mensaje.
    _ticker = Stream.periodic(
            const Duration(seconds: 3), (i) => (i + 1) % _messages.length)
        .asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticker,
      initialData: 0,
      builder: (context, snapshot) {
        // AnimatedSwitcher se encarga de la animación de cambio de texto
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          transitionBuilder: (Widget child, Animation<double> animation) {
            // Animación de desvanecimiento (fade) y un ligero deslizamiento
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.3), // Empieza desde abajo
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            // La clave (key) es MUY IMPORTANTE. Le dice a AnimatedSwitcher
            // que el widget ha cambiado y debe animar la transición.
            _messages[snapshot.data ?? 0],
            key: ValueKey<int>(snapshot.data ?? 0),
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: FrutiaColors.primaryText.withOpacity(0.8),
            ),
          ),
        );
      },
    );
  }
}
