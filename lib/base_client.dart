// import 'package:dio/dio.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class BaseClient {
//   // final auth = FirebaseAuth.instance;

//   static String baseUrl = "";
//   static Dio dio = Dio();

//   BaseClient(String url) {
//     baseUrl = url;
//     dio = Dio(
//       BaseOptions(
//         baseUrl: baseUrl,
//       ),
//     );
//   }

//   void addFirebaseToDio(String idToken) async {
//     dio = Dio(
//       BaseOptions(
//         baseUrl: baseUrl,
//         headers: {"idToken": await getAuthToken()},
//       ),
//     );
//   }

//   // final fcmToken = FirebaseMessaging.instance;

//   static Future<String?> getAuthToken() async {
//     final auth = FirebaseAuth.instance;
//     if (auth.currentUser == null) {
//       return null;
//     }
//     final s = await auth.currentUser!.getIdToken();
//     return s;
//   }

//   static void printAuthTokenForTest() async {
//     final user = FirebaseAuth.instance.currentUser!;
//     String? firebaseIdToken = await user.getIdToken();
//     while (firebaseIdToken!.isNotEmpty) {
//       int startTokenLength =
//           (firebaseIdToken.length >= 500 ? 500 : firebaseIdToken.length);
//       print("TokenPart: ${firebaseIdToken.substring(0, startTokenLength)}");
//       int lastTokenLength = firebaseIdToken.length;
//       firebaseIdToken =
//           firebaseIdToken.substring(startTokenLength, lastTokenLength);
//     }
//     // print(firebaseIdToken);
//   }

//   // Future<String?> getFCMToken() async {
//   //   var s = await fcmToken.getToken();
//   //   return s;
//   // }

//   // void printFCMToken() async {
//   //   var s = await fcmToken.getToken();
//   //   print("FCM TOKEN: $s");
//   // }

//   // Future<void> launchBrowserWithUrl(Uri url) async {
//   //   if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
//   //     print('Could not launch $url');
//   //   }
//   // }
// }
