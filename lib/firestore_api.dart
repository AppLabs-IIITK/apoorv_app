import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreApi {
  static const String googleClientId =
      '389271534594-f2ki17289n40i9iei81s0f48g13sf04k.apps.googleusercontent.com';

  /// Emulates POST /auth/google
  ///
  /// Request shape:
  /// - idToken?: string
  /// - firebaseIdToken?: string
  ///
  /// Response shape:
  /// - success path: { customToken, user: { uid, email, rollNumber?, isNewUser } }
  /// - failure path: { error, message }
  Future<Map<String, dynamic>> authGoogle({
    String? idToken,
    String? firebaseIdToken,
  }) async {
    try {
      if ((idToken == null || idToken.isEmpty) &&
          (firebaseIdToken == null || firebaseIdToken.isEmpty)) {
        return {
          'error': 'Bad Request',
          'message': 'idToken or firebaseIdToken is required',
        };
      }

      UserCredential? userCredential;
      User? user;

      if (idToken != null && idToken.isNotEmpty) {
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        user = userCredential.user;
      } else {
        // Client SDK cannot verify Firebase ID token like Admin SDK.
        // For local emulation, rely on current authenticated user.
        user = FirebaseAuth.instance.currentUser;
      }

      if (user == null) {
        return {
          'error': 'Unauthorized',
          'message': 'Invalid ID token',
        };
      }

      final email = (user.email ?? '').trim();
      if (email.isEmpty) {
        return {
          'error': 'Unauthorized',
          'message': 'Invalid ID token',
        };
      }

      if (user.emailVerified != true) {
        return {
          'error': 'Unauthorized',
          'message': 'Email not verified',
        };
      }

      final fromCollege = email.endsWith('iiitkottayam.ac.in');
      final rollNumber = fromCollege ? _extractRollNumber(email) : null;
      final emailLocalPart = email.split('@').first;
      final photoUrl = user.photoURL;

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snap = await userDoc.get();
      final isNewUser = !snap.exists;

      if (isNewUser) {
        await userDoc.set({
          'uid': user.uid,
          'email': email,
          'emailLocalPart': emailLocalPart,
          'rollNumber': rollNumber,
          'photoUrl': photoUrl,
          'phone': '',
          'fromCollege': fromCollege,
          'collegeName': fromCollege ? 'IIIT Kottayam' : 'Outside College',
          'points': fromCollege ? 50 : 0,
          'name': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Do nothing for local version. Server version updates lastLogin timestamp and other details.
      }

      // Admin SDK would return a custom token.
      // For client-side emulation, return current ID token under the same key.
      final customToken = await user.getIdToken();

      return {
        'customToken': customToken,
        'user': {
          'uid': user.uid,
          'email': email,
          if (rollNumber != null) 'rollNumber': rollNumber,
          'isNewUser': isNewUser,
        },
      };
    } catch (error) {
      return {
        'error': 'Internal Server Error',
        'message': error.toString(),
      };
    }
  }

  /// Emulates POST /transaction
  ///
  /// Request shape:
  /// - to?: string
  /// - toUid?: string
  /// - amount: number|string
  /// - mode?: "shop" | "user"
  ///
  /// Response shape:
  /// - success: { success, message, transactionId, fromPoints, fromShopPoints, toPoints }
  /// - failure: { success, message }
  Future<Map<String, dynamic>> transaction({
    String? to,
    String? toUid,
    required dynamic amount,
    String? mode,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'Unauthorized',
        };
      }

      final fromUid = currentUser.uid;
      final target = (to ?? toUid ?? '').toString().trim();
      final parsedAmount =
          amount is num ? amount.toInt() : int.tryParse(amount.toString());
      final rawMode = (mode ?? 'user').toString().trim().toLowerCase();
      final txnMode = rawMode == 'shop' ? 'shop' : 'user';

      if (target.isEmpty) {
        return {
          'success': false,
          'message': 'to is required',
        };
      }
      if (parsedAmount == null || parsedAmount <= 0) {
        return {
          'success': false,
          'message': 'amount must be > 0',
        };
      }
      if (target == fromUid) {
        return {
          'success': false,
          'message': 'cannot send to self',
        };
      }

      final db = FirebaseFirestore.instance;
      final fromRef = db.collection('users').doc(fromUid);
      final toRef = db.collection('users').doc(target);
      final txnRef = db.collection('transactions').doc();

      // Flutter transactions cannot run queries inside transaction callback.
      // Mirror server-side check as closely as possible with a pre-check.
      bool existingShopReward = false;
      if (txnMode == 'shop') {
        final existingSnap = await db
            .collection('transactions')
            .where('from', isEqualTo: fromUid)
            .where('to', isEqualTo: target)
            .where('type', isEqualTo: 'shop')
            .limit(1)
            .get();
        existingShopReward = existingSnap.docs.isNotEmpty;
      }

      final result = await db.runTransaction((t) async {
        final fromSnap = await t.get(fromRef);
        final toSnap = await t.get(toRef);
        if (!fromSnap.exists) {
          throw _TxnException('from-user-not-found');
        }
        if (!toSnap.exists) {
          throw _TxnException('to-user-not-found');
        }

        final fromData = fromSnap.data() ?? <String, dynamic>{};
        final toData = toSnap.data() ?? <String, dynamic>{};

        final fromPoints =
            (fromData['points'] is int) ? fromData['points'] as int : 0;
        final toPoints = (toData['points'] is int) ? toData['points'] as int : 0;
        final fromShopPoints =
            (fromData['shopPoints'] is int) ? fromData['shopPoints'] as int : 0;
        final isShopkeeper = fromData['isShopkeeper'] == true;

        final fromEmail = ((fromData['email'] ?? currentUser.email ?? '') as String);
        final toEmail = ((toData['email'] ?? '') as String);
        final fromName =
            ((fromData['name'] ?? fromData['fullName'] ?? '') as String);
        final toName = ((toData['name'] ?? toData['fullName'] ?? '') as String);

        bool? adminOk;
        Future<bool> allowAdminBypass() async {
          if (adminOk != null) return adminOk!;
          final configRef = db.collection('app_config').doc('global');
          final configSnap = await t.get(configRef);
          final fromEmailNorm = fromEmail.trim().toLowerCase();
          final adminEmails = (configSnap.data()?['adminEmails'] is List)
              ? List<dynamic>.from(configSnap.data()!['adminEmails'] as List)
              : const <dynamic>[];
          adminOk = fromEmailNorm.isNotEmpty &&
              adminEmails.any(
                (e) => e.toString().trim().toLowerCase() == fromEmailNorm,
              );
          return adminOk!;
        }

        if (txnMode == 'shop') {
          if (!isShopkeeper) {
            throw _TxnException('not-shopkeeper');
          }
          if (parsedAmount > 150 && !(await allowAdminBypass())) {
            throw _TxnException('shop-limit-exceeded');
          }
          if (fromShopPoints < parsedAmount) {
            throw _TxnException('insufficient-shop-points');
          }
          if (existingShopReward && !(await allowAdminBypass())) {
            throw _TxnException('shop-limit-reached');
          }

          t.update(fromRef, {'shopPoints': fromShopPoints - parsedAmount});
          t.update(toRef, {'points': toPoints + parsedAmount});
        } else {
          if (fromPoints < parsedAmount) {
            throw _TxnException('insufficient-points');
          }
          t.update(fromRef, {'points': fromPoints - parsedAmount});
          t.update(toRef, {'points': toPoints + parsedAmount});
        }

        t.set(txnRef, {
          'from': fromUid,
          'to': target,
          'involvedPartiesUids': [fromUid, target],
          'involvedPartiesEmails': [
            fromEmail.trim().toLowerCase(),
            toEmail.trim().toLowerCase(),
          ],
          'fromName': fromName,
          'toName': toName,
          'fromEmail': fromEmail,
          'toEmail': toEmail,
          'transactionValue': parsedAmount,
          'updatedAt': FieldValue.serverTimestamp(),
          'type': txnMode,
        });

        return {
          'transactionId': txnRef.id,
          'fromPoints': txnMode == 'shop' ? fromPoints : fromPoints - parsedAmount,
          'fromShopPoints':
              txnMode == 'shop' ? fromShopPoints - parsedAmount : fromShopPoints,
          'toPoints': toPoints + parsedAmount,
        };
      });

      return {
        'success': true,
        'message': 'Transaction completed successfully',
        ...result,
      };
    } on _TxnException catch (e) {
      if (e.code == 'insufficient-points') {
        return {'success': false, 'message': 'Insufficient points'};
      }
      if (e.code == 'insufficient-shop-points') {
        return {'success': false, 'message': 'Insufficient shop points'};
      }
      if (e.code == 'not-shopkeeper') {
        return {'success': false, 'message': 'Not a shopkeeper'};
      }
      if (e.code == 'shop-limit-exceeded') {
        return {
          'success': false,
          'message': 'Shop rewards are limited to 150 points per person',
        };
      }
      if (e.code == 'shop-limit-reached') {
        return {
          'success': false,
          'message': 'You have already rewarded this user with shop points',
        };
      }
      if (e.code == 'from-user-not-found' || e.code == 'to-user-not-found') {
        return {'success': false, 'message': 'User not found'};
      }
      return {'success': false, 'message': 'Failed to process transaction'};
    } catch (_) {
      return {'success': false, 'message': 'Failed to process transaction'};
    }
  }

  String? _extractRollNumber(String email) {
    if (!email.endsWith('iiitkottayam.ac.in')) return null;
    final localPart = email.split('@').first;
    final regExp = RegExp(r'(\d+)([a-zA-Z]+)(\d+)');
    final match = regExp.firstMatch(localPart);
    if (match == null) return null;
    final year = match.group(1)!;
    final branch = match.group(2)!.toUpperCase();
    final number = match.group(3)!.padLeft(4, '0');
    return '20$year$branch$number';
  }
}

class _TxnException implements Exception {
  final String code;
  _TxnException(this.code);
}

