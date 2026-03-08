import '../../../providers/receiver_provider.dart';
import '../../../providers/app_config_provider.dart';
import '../../../providers/user_info_provider.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/spinning_apoorv.dart';
import 'payment_success.dart';
import '../../../widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../constants.dart';
import '../../../widgets/profile_avatar.dart';
import 'inspect_transactions.dart';

class Payment extends StatefulWidget {
  static const routeName = '/payment';
  const Payment({super.key});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  final TextEditingController amountController = TextEditingController();

  Future<Map<String, dynamic>>? _myFuture;

  var isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Load shopkeeper mode preference (if any).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().ensureShopkeeperModeLoaded();
    });

    // Get arguments if passed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      // Check if arguments were passed (from modal/leaderboard) - prioritize these
      if (args != null && args['fromSearch'] == true) {
        // Coming from modal with arguments - always use these fresh arguments
        final email = args['email']?.toString() ?? '';

        // If email is missing, fetch full user data
        if (email.isEmpty) {
          final uid = args['uid']?.toString() ?? '';
          if (uid.isNotEmpty) {
            context.read<ReceiverProvider>().setUID(uid);
            setState(() {
              _myFuture = context.read<ReceiverProvider>().setReceiverData(context);
            });
          } else {
            setState(() {
              _myFuture = Future.value({'success': false, 'message': 'Invalid user'});
            });
          }
        } else {
          // Update provider with new data from arguments
          context.read<ReceiverProvider>().setReceiverDataFromSearch(args);
          setState(() {
            _myFuture = Future.value({'success': true});
          });
        }
      } else if (context.read<ReceiverProvider>().fromSearch) {
        // Coming from search via provider (no arguments passed)
        setState(() {
          _myFuture = Future.value({'success': true});
        });
      } else {
        // Default: fetch receiver data (QR scan)
        setState(() {
          _myFuture = Provider.of<ReceiverProvider>(context, listen: false)
              .setReceiverData(context);
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // var args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // String to_uid;

    // if(args['fromScan'])
    // {
    //   to_uid = args['uid'];
    // }

    // var to_uid = "123457";

    // var to_user = {
    //   "uid": "123457",
    //   "name": "AbraCAdabra",
    //   "email": "user@example.com",
    // };

    return FutureBuilder(
      future: _myFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Scaffold(
              body: Center(
                child: SpinningApoorv(),
              ),
            );

          case ConnectionState.done:
          default:
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text(snapshot.error.toString())),
              );
            } else if (snapshot.hasData) {
              // print(snapshot.data);
              if (snapshot.data['success']) {
                final userProvider = context.read<UserProvider>();
                final useShopkeeperPoints =
                    userProvider.isShopkeeper && userProvider.shopkeeperModeEnabled;
                return Scaffold(
                  appBar: AppBar(
                      // title: const IconButton(onPressed: null, icon: Icon(Icons.arrow_back)),
                      actions: [
                        IconButton(
                          onPressed: () {
                            final receiver = context.read<ReceiverProvider>();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => InspectTransactionsScreen(
                                  uid: receiver.uid,
                                  name: receiver.userName,
                                  email: receiver.userEmail,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.receipt_long,
                            size: 18,
                            color: Colors.white54,
                          ),
                          tooltip: 'Inspect',
                        ),
                      ],
                      ),
                  body: SafeArea(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.05,
                          left: MediaQuery.of(context).size.width * 0.05,
                          right: MediaQuery.of(context).size.width * 0.05,
                          bottom: MediaQuery.of(context).size.height * 0.05,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(),
                            Column(
                              children: [
                                CircleAvatar(
                                  radius: MediaQuery.of(context).size.width * 0.2,
                                  backgroundColor: Constants.yellowColor,
                                  child: ProfileAvatar(
                                    imageUrl: context
                                        .read<ReceiverProvider>()
                                        .profilePhotoUrl,
                                    name: context.read<ReceiverProvider>().userName,
                                    radius: MediaQuery.of(context).size.width * 0.2,
                                    backgroundColor: Constants.yellowColor,
                                    textColor: Constants.blackColor,
                                  ),
                                ),
                                Constants.gap,
                                Constants.gap,
                                Text(
                                  "Paying ${context.read<ReceiverProvider>().userName}",
                                  style: const TextStyle(fontSize: 24),
                                ),
                                Text(
                                  context.read<ReceiverProvider>().userEmail,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                if (useShopkeeperPoints) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    "Using shopkeeper points",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                                SizedBox(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 160,
                                        child: TextField(
                                          controller: amountController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(4),
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            hintText: '0',
                                          ),
                                          style: const TextStyle(
                                              fontSize: 72, color: Colors.white),
                                        ),
                                      ),
                                      const Text(
                                        "pts",
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Stack(
                            //   alignment: Alignment.center,
                            //   children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.05),
                              child: FilledButton(
                                onPressed: isProcessing
                                    ? null
                                    : () async {
                                        if (amountController.text.isNotEmpty &&
                                            int.parse(amountController.text) > 0) {
                                          final useFirestoreApi = Provider.of<AppConfigProvider>(context, listen: false)
                                                  .apiMode
                                                  .trim()
                                                  .toLowerCase() ==
                                              'firestore';
                                          if (!isProcessing) {
                                            setState(() {
                                              isProcessing = true;
                                            });
                                          }
                                          var response =
                                              await Provider.of<UserProvider>(
                                            context,
                                            listen: false,
                                          ).doATransaction(
                                            context.read<ReceiverProvider>().uid,
                                            int.parse(amountController.text),
                                            mode: useShopkeeperPoints ? 'shop' : 'user',
                                            useFirestoreApi: useFirestoreApi,
                                          );
                                          setState(() {
                                            isProcessing = false;
                                          });

                                          if (context.mounted) {
                                            if (response['success']) {
                                              Provider.of<ReceiverProvider>(context,
                                                      listen: false)
                                                  .setAmount(
                                                int.parse(amountController.text),
                                              );

                                              Navigator.of(context)
                                                  .pushReplacementNamed(
                                                      PaymentSuccess.routeName);
                                            } else {
                                              dialogBuilder(
                                                context,
                                                message: response['message'],
                                                function: () =>
                                                    Navigator.of(context).pop(),
                                              );
                                              showSnackbarOnScreen(
                                                  context, response['message']);
                                            }
                                          }
                                        } else {
                                          showSnackbarOnScreen(
                                              context, "Amount must be positive!");
                                        }
                                      },
                                // style: ButtonStyle(
                                //   backgroundColor: MaterialStateProperty.all<Color>(
                                //       Constants.redColor),
                                //   foregroundColor: MaterialStateProperty.all<Color>(
                                //       Constants.whiteColor),

                                // ),
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    child: isProcessing
                                        ? const SpinningApoorv()
                                        : const Text(
                                            'Continue',
                                            style: TextStyle(fontSize: 20),
                                            textAlign: TextAlign.center,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            // if (isProcessing) const CircularProgressIndicator(),
                            // ],
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                Future.delayed(
                  Duration.zero,
                  () {
                    if (!context.mounted) return;
                    showSnackbarOnScreen(
                        context, snapshot.data['message'] + 'in else');
                  },
                );
                return Center(child: Text(snapshot.data['message']));
              }
            } else {
              return const Scaffold(body: Center(child: SpinningApoorv()));
            }
        }
      },
    );
  }
}
