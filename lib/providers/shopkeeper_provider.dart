import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../widgets/points-widget/transactions.dart';

class ShopkeeperProvider extends ChangeNotifier {
  String shopkeeperEmail;
  String shopkeeperPassword;
  String profilePhoto;
  int shopPoints = 0;
  List<int> pointsArray = [];
  String idToken;
  String uid;

  List<TransactionsWidget> transactions = [];

  ShopkeeperProvider({
    this.shopkeeperEmail = " ",
    this.profilePhoto = " ",
    this.shopkeeperPassword = " ",
    this.idToken = " ",
    this.uid = " ",
  });

  void updateShopkeeper({
    required String shopEmail,
    required String shopPass,
  }) {
    shopkeeperEmail = shopEmail;
    shopkeeperPassword = shopPass;
    notifyListeners();
  }

  void updateProfilePhoto(String pf) {
    profilePhoto = pf;
    notifyListeners();
  }

  void refreshUID({bool? listen}) {
    uid = FirebaseAuth.instance.currentUser!.uid;
    if (listen == null || listen == true) {
      notifyListeners();
    }
  }

  void refreshIdToken({bool? listen}) async {
    idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
    if (listen == null || listen == true) {
      notifyListeners();
    }
  }

  void updateEmail(String em) {
    shopkeeperEmail = em;
    notifyListeners();
  }

  void refreshGoogleServiceData() async {
    refreshUID();
    refreshIdToken();
    updateEmail(FirebaseAuth.instance.currentUser!.email!);
    if (FirebaseAuth.instance.currentUser!.photoURL != null) {
      updateProfilePhoto(FirebaseAuth.instance.currentUser!.photoURL!);
    }
  }

  void updatePoints(int newPoints) {
    shopPoints = newPoints;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    refreshUID(listen: false);
    refreshIdToken(listen: true);

    var args = {
      "from": uid,
      "password": shopkeeperPassword,
      "email": shopkeeperEmail,
    };

    var res = await APICalls().getUserDataAPI(uid, idToken, args: args);
    print("res get user api: $res");
    if (res['success']) {
      updateEmail(res['email']);
      updateProfilePhoto(res['photoUrl']);
      updatePoints(res['shopPoints'] ?? res['points']);
      notifyListeners();
    }
    return res;
  }

  Future<Map<String, dynamic>> getLatest2Transactions() async {
    var res = await getUserTransactions();
    if (transactions.isNotEmpty) {
      res['transactions'] =
          transactions.sublist(0, min(2, transactions.length));
    }
    return res;
  }

  Future<Map<String, dynamic>> getUserTransactions() async {
    refreshIdToken(listen: false);
    var res = await APICalls().getAllTransactions(idToken, uid);
    // print(res['success']);
    if (res['success']) {
      transactions.clear();
      if (res['transactions'].isNotEmpty) {
        for (var txn in res['transactions']) {
          final rawTs = txn['updatedAt'];
          DateTime utcTime;
          if (rawTs is Timestamp) {
            utcTime = rawTs.toDate().toLocal();
          } else if (rawTs is DateTime) {
            utcTime = rawTs.toLocal();
          } else {
            utcTime = DateTime.parse(rawTs.toString()).toLocal();
          }
          String formattedTime =
              DateFormat("MMMM d, yyyy 'at' h:mm a").format(utcTime);
          if (txn['from'] == uid || (txn['fromEmail'] != null && txn['fromEmail'].toString().trim().toLowerCase() == shopkeeperEmail.trim().toLowerCase())) {
            transactions.add(TransactionsWidget(
              name: txn['toName'],
              date: formattedTime,
              type: 'debit',
              points: txn['transactionValue'],
              isShop:
                  (txn['type'] ?? 'user').toString().toLowerCase() == 'shop',
            ));
          } else if (txn['to'] == uid || (txn['toEmail'] != null && txn['toEmail'].toString().trim().toLowerCase() == shopkeeperEmail.trim().toLowerCase())) {
            transactions.add(TransactionsWidget(
              name: txn['fromName'],
              date: formattedTime,
              type: 'credit',
              points: txn['transactionValue'],
              isShop:
                  (txn['type'] ?? 'user').toString().toLowerCase() == 'shop',
            ));
          }
        }
      }
      notifyListeners();
      return {
        'success': res['success'],
        'message': res['message'],
      };
    }
    return {
      'success': res['success'],
      'error': res['error'],
    };
  }
}
