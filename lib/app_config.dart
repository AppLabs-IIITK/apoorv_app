class AppConfig {
  // Hardcoded for now.
  // Deployed URL will be: https://asia-south1-apoorv-iiitk.cloudfunctions.net/api
  static const String functionsBaseUrl =
      "https://asia-south1-apoorv-iiitk.cloudfunctions.net/api";

  // Local emulator base (Functions)
  // http://127.0.0.1:5001/apoorv-iiitk/asia-south1/api
  static const String functionsEmulatorBaseUrl =
      "http://127.0.0.1:5001/apoorv-iiitk/asia-south1/api";

  static const bool useEmulator = false;

  static String get functionsUrl =>
      useEmulator ? functionsEmulatorBaseUrl : functionsBaseUrl;
}
