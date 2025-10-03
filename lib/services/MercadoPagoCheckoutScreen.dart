import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Importa los paquetes específicos de la plataforma si es necesario
// import 'package:webview_flutter_android/webview_flutter_android.dart';
// import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Una pantalla que muestra el checkout de MercadoPago dentro de un WebView.
class MercadoPagoCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;

  const MercadoPagoCheckoutScreen({Key? key, required this.checkoutUrl})
      : super(key: key);

  @override
  State<MercadoPagoCheckoutScreen> createState() =>
      _MercadoPagoCheckoutScreenState();
}

class _MercadoPagoCheckoutScreenState extends State<MercadoPagoCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // Manejar errores si es necesario
            debugPrint('Error en WebView: ${error.description}');
          },
          // --- ESTA ES LA PARTE MÁS IMPORTANTE ---
          // Se llama cada vez que el WebView intenta navegar a una nueva URL.
          onNavigationRequest: (NavigationRequest request) {
            // Verificamos si la URL es una de nuestras URLs de retorno.
            if (request.url.startsWith('frutiapp://payment')) {
              // Extraemos el estado del pago ('success', 'failure', 'pending')
              final status = Uri.parse(request.url).pathSegments.last;

              // Cerramos la pantalla de WebView y devolvemos el estado.
              Navigator.of(context).pop(status);

              // Prevenimos que el WebView intente navegar a 'frutiapp://...'
              return NavigationDecision.prevent;
            }
            // Para cualquier otra URL (dentro del flujo de MercadoPago), permitimos la navegación.
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Pago'),
        backgroundColor: FrutiaColors.accent,
        elevation: 2,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: FrutiaColors.accent),
            ),
        ],
      ),
    );
  }
}
