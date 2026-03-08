import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EventRegistrationService {
  static Future<bool> openRegistrationLink(
    BuildContext context,
    String? registrationLink,
  ) async {
    final link = registrationLink?.trim();
    if (link == null || link.isEmpty) {
      _showMessage(context, 'Registration is not available for this event yet.');
      return false;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      _showMessage(context, 'This registration link is invalid.');
      return false;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      _showMessage(context, 'Could not open the registration link.');
    }

    return launched;
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
