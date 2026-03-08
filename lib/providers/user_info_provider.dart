// ignore_for_file: avoid_print

import 'dart:math';

import 'package:apoorv_app/api.dart';
import 'package:apoorv_app/widgets/points-widget/transactions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String userName = "Your Name";
  String userCollegeName = "IIIT Kottayam";
  String? userRollNo;
  String userPhNo = "000000000";
  String? profilePhotoUrl =
      'https://t3.ftcdn.net/jpg/02/43/12/34/360_F_243123463_zTooub557xEWABDLk0jJklDyLSGl2jrr.jpg';
  String userEmail = "nobody@noreply.com";
  bool fromCollege = true;

  List<TransactionsWidget> transactions = [];
  List<Map<String, dynamic>> transactionData = [];

  String uid = "Nothing to see here";
  String idToken = "somerandomidtoken";

  int points = 0;
  int shopPoints = 0;
  bool isShopkeeper = false;
  bool shopkeeperModeEnabled = false;
  bool _shopkeeperModeLoaded = false;

  // UserProvider({
  //   this.userName = "Full Name",
  //   this.userCollegeName,
  //   this.userRollNo,
  //   this.userPhNo = "Phone Number",
  //   this.profilePhotoUrl,
  //   this.userEmail = "",
  // });

  void changeSameCollegeDetails({
    required String newUserName,
    String? newUserRollNo,
    required String newUserPhNo,
  }) {
    userName = newUserName;
    userPhNo = newUserPhNo;
    userCollegeName = 'IIIT Kottayam';
    userRollNo = (newUserRollNo == null || newUserRollNo.trim().isEmpty)
        ? null
        : newUserRollNo.trim();
    fromCollege = true;
    notifyListeners();
  }

  void changeOtherCollegeDetails({
    required String newUserName,
    required String newUserCollegeName,
    required String newUserPhNo,
  }) {
    userName = newUserName;
    userPhNo = newUserPhNo;
    userCollegeName = newUserCollegeName;
    fromCollege = false;
    userRollNo = null;
    notifyListeners();
  }

  void updateProfilePhoto(String pf) {
    profilePhotoUrl = pf;
    notifyListeners();
  }

  void updateEmail(String em) {
    userEmail = em;
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

  void updatePoints(int newPoints) {
    points = newPoints;
    notifyListeners();
  }

  void updateShopPoints(int newPoints) {
    shopPoints = newPoints;
    notifyListeners();
  }

  void updateIsShopkeeper(bool value) {
    isShopkeeper = value;
    notifyListeners();
  }

  Future<void> ensureShopkeeperModeLoaded() async {
    if (_shopkeeperModeLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    shopkeeperModeEnabled = prefs.getBool('shopkeeper_mode_enabled') ?? false;
    _shopkeeperModeLoaded = true;
    notifyListeners();
  }

  Future<void> setShopkeeperModeEnabled(bool value) async {
    shopkeeperModeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shopkeeper_mode_enabled', value);
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

  Future<Map<String, dynamic>> uploadUserData(Map<String, dynamic> args) async {
    var response = await APICalls().uploadUserData(args, idToken);
    return response;
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    refreshUID(listen: false);
    refreshIdToken(listen: true);

    var res = await APICalls().getUserDataAPI(uid, idToken);
    // print("res: $res");
    if (res['success']) {
      if (res['fromCollege']) {
        final roll = res['rollNumber'];
        changeSameCollegeDetails(
          newUserName: res['fullName'],
          // rollNumber may be null/absent for staff emails like registrar@...
          newUserRollNo: roll is String ? roll : null,
          newUserPhNo: res['phone'],
        );
      } else {
        changeOtherCollegeDetails(
          newUserName: res['fullName'],
          newUserCollegeName: res['collegeName'],
          newUserPhNo: res['phone'],
        );
      }
      updateEmail(res['email']);
      updateProfilePhoto(res['photoUrl']);
      updatePoints(res['points']);
      updateShopPoints(res['shopPoints'] ?? 0);
      updateIsShopkeeper(res['isShopkeeper'] ?? false);
      notifyListeners();
    }
    return res;
  }

  Future<Map<String, dynamic>> doATransaction(
    String to,
    int amount, {
    String? mode,
    bool useFirestoreApi = false,
  }) async {
    refreshUID(listen: false);
    // refreshIdToken(listen: false);
    await Future.delayed(
      const Duration(seconds: 1),
      () {},
    );
    var response = await APICalls().transactionAPI(
      uid,
      to,
      amount,
      mode: mode,
      useFirestoreApi: useFirestoreApi,
      // idToken,
    );
    print("Response from provider-> $response");
    if (response['success']) {
      notifyListeners();
    }
    return response;
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
      transactionData.clear();
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

          // Store raw transaction data
          transactionData.add({
            'from': txn['from'],
            'to': txn['to'],
            'fromName': txn['fromName'],
            'toName': txn['toName'],
            'fromEmail': txn['fromEmail'],
            'toEmail': txn['toEmail'],
            'transactionValue': txn['transactionValue'],
            'updatedAt': utcTime,
            'formattedTime': formattedTime,
          });

          final String fromEmail = (txn['fromEmail'] ?? '').toString().trim().toLowerCase();
          final String toEmail = (txn['toEmail'] ?? '').toString().trim().toLowerCase();
          final String currentEmail = userEmail.trim().toLowerCase();

          final bool isDebit = (fromEmail.isNotEmpty && fromEmail == currentEmail) || txn['from'] == uid;
          final bool isCredit = (toEmail.isNotEmpty && toEmail == currentEmail) || txn['to'] == uid;

          if (isDebit) {
            transactions.add(TransactionsWidget(
              name: txn['toName'],
              date: formattedTime,
              type: 'debit',
              points: txn['transactionValue'],
              isShop:
                  (txn['type'] ?? 'user').toString().toLowerCase() == 'shop',
              fromUid: txn['from']?.toString(),
              toUid: txn['to']?.toString(),
              fromEmail: txn['fromEmail']?.toString(),
              toEmail: txn['toEmail']?.toString(),
            ));
          } else if (isCredit) {
            transactions.add(TransactionsWidget(
              name: txn['fromName'],
              date: formattedTime,
              type: 'credit',
              points: txn['transactionValue'],
              isShop:
                  (txn['type'] ?? 'user').toString().toLowerCase() == 'shop',
              fromUid: txn['from']?.toString(),
              toUid: txn['to']?.toString(),
              fromEmail: txn['fromEmail']?.toString(),
              toEmail: txn['toEmail']?.toString(),
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
