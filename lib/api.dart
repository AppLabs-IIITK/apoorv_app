import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'app_config.dart';

class APICalls {
  Future<Map<String, dynamic>> getUserDataAPI(String uid, String idToken,
      {Map<String, dynamic>? args}) async {
    // Firestore is the source of truth for user profile data.
    // Keep the return shape compatible with the old REST response.
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!snap.exists) {
        return {
          'success': false,
          'error': 'user-not-found',
        };
      }

      final data = snap.data() ?? <String, dynamic>{};
      final currentUser = FirebaseAuth.instance.currentUser;

      final email = (data['email'] as String?)?.trim() ??
          (currentUser?.email?.trim() ?? '');

      // Fallback chain: Firestore photoUrl -> Firebase Auth photoURL -> empty string
      final firestorePhotoUrl = (data['photoUrl'] as String?)?.trim() ?? '';
      final authPhotoUrl = currentUser?.photoURL?.trim() ?? '';
      final photoUrl = firestorePhotoUrl.isNotEmpty ? firestorePhotoUrl : authPhotoUrl;

      final fullName = (data['fullName'] as String?)?.trim();
      final name = (data['name'] as String?)?.trim();
      final pointsValue = data['points'];
      final shopPointsValue = data['shopPoints'];
      final isShopkeeperValue = data['isShopkeeper'];

      return {
        'success': true,
        'message': 'Your user data has been updated',
        'uid': uid,
        'email': email,
        'photoUrl': photoUrl,
        'rollNumber': data['rollNumber'],
        'fromCollege': data['fromCollege'] ?? true,
        'collegeName': data['collegeName'] ?? 'IIIT Kottayam',
        'phone': data['phone'] ?? '',
        'points': pointsValue is int ? pointsValue : 0,
        'shopPoints': shopPointsValue is int ? shopPointsValue : 0,
        'isShopkeeper':
            isShopkeeperValue is bool ? isShopkeeperValue : false,
        // App screens/providers currently expect this key.
        'fullName': (name != null && name.isNotEmpty)
            ? name
            : (fullName ?? ''),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> uploadUserData(
    Map<String, dynamic> args,
    String idToken,
  ) async {
    // Firestore is the source of truth for user profile data.
    // Keep this method so existing call sites still work.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'Not signed in',
        };
      }

      final update = <String, dynamic>{};

      // Accept legacy keys but only persist what we allow users to edit.
      final fullName = (args['fullName'] ?? args['name'])?.toString().trim();
      if (fullName != null && fullName.isNotEmpty) {
        update['name'] = fullName;
        update['nameLower'] = fullName.toLowerCase();
      }

      final phone = args['phone']?.toString().trim();
      if (phone != null) {
        update['phone'] = phone;
      }

      if (update.isEmpty) {
        return {
          'success': true,
          'message': 'Nothing to update',
        };
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(update, SetOptions(merge: true));

      return {
        'success': true,
        'message': 'Profile updated',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getAllTransactions(
    String idToken,
    String uid,
  ) async {
    try {
      final page = await getUserTransactionsPage(limit: 20);
      if (page['success'] == true) {
        return {
          'success': true,
          'transactions': page['transactions'] ?? <dynamic>[],
          'message': 'Transactions fetched',
        };
      }

      return {
        'success': false,
        'error': page['error'] ?? 'failed-to-fetch',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getUserTransactionsPage({
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    int limit = 20,
  }) async {
    try {
      final email =
          FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) {
        return {
          'success': false,
          'error': 'missing-email',
        };
      }

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('transactions')
          .where('involvedPartiesEmails', arrayContains: email)
          .orderBy('updatedAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final txns = snapshot.docs
          .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
          .toList();

      return {
        'success': true,
        'transactions': txns,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length >= limit,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getGlobalTransactions({
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('updatedAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final txns = snapshot.docs
          .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
          .toList();

      return {
        'success': true,
        'transactions': txns,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length >= limit,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> transactionAPI(
    String from,
    String to,
    int amount,
    // String idToken,
    {String? mode}
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'Not signed in',
        };
      }

      final idToken = await user.getIdToken();
      final url = Uri.parse('${AppConfig.functionsUrl}/transaction');
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'from': from,
          'to': to,
          'amount': amount,
          if (mode != null) 'mode': mode,
        }),
      );

      final body = resp.body.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(resp.body) as Map<String, dynamic>);

      if (resp.statusCode == 200 && body['success'] == true) {
        return {
          'success': true,
          'message': body['message'] ?? 'Transaction completed successfully',
          'transactionId': body['transactionId'],
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Transaction failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getLeaderboardPage({
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          // Tie-breaker for stable pagination when points are equal.
          .orderBy('uid')
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snap = await query.get();

      final results = snap.docs.map((d) {
        final u = d.data();
        final name = (u['name'] as String?)?.trim();
        final legacyName = (u['fullName'] as String?)?.trim();
        final firestorePhoto = (u['photoUrl'] as String?)?.trim() ?? '';

        return {
          'uid': u['uid'] ?? d.id,
          'fullName': (name != null && name.isNotEmpty)
              ? name
              : (legacyName ?? 'Unknown'),
          'email': u['email'] ?? '',
          'points': u['points'] ?? 0,
          'profileImage': firestorePhoto,
        };
      }).toList();

      return {
        'success': true,
        'results': results,
        'lastDocument': snap.docs.isNotEmpty ? snap.docs.last : null,
        'hasMore': snap.docs.length >= limit,
        'message': 'Leaderboard page fetched',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getFeed(String idToken) async {
    try {
      // Firestore-backed feed.
      // Stored as a single doc so Home tab can fetch in one read.
      final doc = await FirebaseFirestore.instance
          .collection('feed')
          .doc('latest')
          .get();

      final data = doc.data();
      final raw = (data == null) ? null : data['body'];
      final body = (raw is List) ? raw : <dynamic>[];

      return {
        'success': true,
        'body': body,
        'message': 'Feed fetched',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Updates the entire feed body stored in Firestore at `feed/latest`.
  ///
  /// Feed is stored as a single document with a `body` array so the home tab
  /// can fetch it in one read.
  ///
  /// NOTE: This is intended to be admin-only; enforce via Firestore rules.
  Future<Map<String, dynamic>> updateFeed(
    List<Map<String, dynamic>> body,
    String idToken,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('feed')
          .doc('latest')
          .set({'body': body}, SetOptions(merge: true));

      return {
        'success': true,
        'message': 'Feed updated',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getUsersSearchList(
      String query, String idToken) async {
    try {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        return {
          'success': true,
          'results': <dynamic>[],
          'message': 'Users fetched',
        };
      }

      final seen = <String>{};
      final results = <Map<String, dynamic>>[];

      Future<void> addFromSnap(QuerySnapshot<Map<String, dynamic>> snap) async {
        for (final d in snap.docs) {
          final u = d.data();
          final uid = (u['uid'] ?? d.id).toString();
          if (seen.contains(uid)) continue;
          seen.add(uid);

          final name = (u['name'] as String?)?.trim();
          final legacyName = (u['fullName'] as String?)?.trim();
          final firestorePhoto = (u['photoUrl'] as String?)?.trim() ?? '';

          results.add({
            'uid': uid,
            'fullName': (name != null && name.isNotEmpty)
                ? name
                : (legacyName ?? 'Unknown'),
            'email': u['email'] ?? '',
            'points': u['points'] ?? 0,
            'profileImage': firestorePhoto,
          });
          if (results.length >= 3) return;
        }
      }

      // Prefer nameLower for efficient prefix search.
      final nameSnap = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('nameLower')
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(3)
          .get();
      await addFromSnap(nameSnap);

      // If still short, try email prefix search.
      if (results.length < 3) {
        final emailSnap = await FirebaseFirestore.instance
            .collection('users')
            .orderBy('email')
            .startAt([q])
            .endAt(['$q\uf8ff'])
            .limit(3)
            .get();
        await addFromSnap(emailSnap);
      }

      return {
        'success': true,
        'results': results,
        'message': 'Users fetched',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
