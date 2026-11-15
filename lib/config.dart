/// Backend configuration for Synras AI RAG system.
class AppConfig {
  /// Base URL for the FastAPI backend.
  ///
  /// For Android emulator use: `http://10.0.2.2:8000`
  /// For physical device on same network: `http://<your-pc-ip>:8000`
  /// For iOS simulator: `http://localhost:8000`
  static const String backendBaseUrl = 'http://10.0.2.2:8000';
}
