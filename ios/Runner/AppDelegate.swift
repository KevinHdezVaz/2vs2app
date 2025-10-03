import UIKit
import Flutter
import AVFoundation
import GoogleSignIn  

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configuración avanzada de AVAudioSession (se mantiene tu código original)
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(
        .playback,
        mode: .default,
        policy: .default,
        options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
      )
      try session.setActive(true, options: .notifyOthersOnDeactivation)
      try session.setPreferredSampleRate(44100)
      try session.setPreferredIOBufferDuration(0.005)
      print("✅ Configuración de AVAudioSession completada con éxito")
    } catch {
      print("❌ Error al configurar AVAudioSession: \(error.localizedDescription)")
    }

    // Registrar plugins de Flutter
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // --- FUNCIÓN MODIFICADA PARA GOOGLE SIGN-IN ---
  // Esta función se activa cuando una URL externa intenta abrir tu app.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Intenta pasar la URL al manejador de Google Sign-In.
    // Si la URL corresponde a una respuesta de autenticación de Google,
    // el método 'handle' la procesará y devolverá 'true'.
    var handled: Bool
    
    handled = GIDSignIn.sharedInstance.handle(url)

    if handled {
      return true // La URL fue manejada por Google, el proceso termina aquí.
    }
    
    // Si la URL no fue para Google Sign-In (devuelve 'false'),
    // se llama al método 'super' para que otros plugins o el sistema
    // puedan intentar manejarla.
    return super.application(app, open: url, options: options)
  }
  
  // Configuración adicional para manejo de audio en segundo plano (se mantiene tu código original)
  override func applicationWillResignActive(_ application: UIApplication) {
    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      print("Error al desactivar AVAudioSession: \(error.localizedDescription)")
    }
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Error al reactivar AVAudioSession: \(error.localizedDescription)")
    }
  }
}