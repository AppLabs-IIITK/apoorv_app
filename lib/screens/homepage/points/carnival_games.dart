import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants.dart';
import '../../../providers/app_config_provider.dart';

class CarnivalGamesScreen extends StatelessWidget {
  static const routeName = '/carnival-games';

  const CarnivalGamesScreen({super.key});

  Future<void> _openCarnivalGames(BuildContext context) async {
    const fallbackUrl = 'https://apoorv.fun/home.php';
    final appConfigUrl =
        context.read<AppConfigProvider>().carnivalGamesUrl.trim();
    final launchUrlString =
        appConfigUrl.isNotEmpty ? appConfigUrl : fallbackUrl;
    final Uri url = Uri.parse(launchUrlString);

    try {
      bool launched = false;

      if (kIsWeb) {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        launched = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
      }
      if (launched && context.mounted) {
        // Show success message on web since user might not notice new tab
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Carnival games opened in new tab!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open carnival games website. Please check your internet connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('URL launch error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening carnival games: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.blackColor,
      appBar: AppBar(
        title: const Text(
          'Carnival Games',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Constants.blackColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Constants.gradientHigh,
              Constants.gradientLow,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.games,
                  size: 120,
                  color: Constants.blackColor,
                ),
                const SizedBox(height: 32),
                const Text(
                  '🎯 Carnival Games',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Constants.blackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Step into the Apoorv Carnival and play exciting mini games!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Constants.blackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Win prizes, compete with friends, and have fun!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Constants.blackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _openCarnivalGames(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.blackColor,
                      foregroundColor: Constants.yellowColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.launch, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Play Carnival Games',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Constants.blackColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Constants.blackColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          kIsWeb
                            ? 'This will open the carnival games in a new browser tab where you can sign in and play.'
                            : 'This will open the carnival games in your browser where you can sign in and play.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Constants.blackColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
