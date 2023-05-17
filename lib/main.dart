import 'package:flutter/material.dart';
import 'package:payment_example/service/evn.dart';
import 'package:payment_example/service/local_storage.dart';
import 'package:surfboard_ttp/surfboard_ttp.dart';
import 'package:surfboard_ttp/models/order_model/order_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocalStorage.initialize();
  runApp(const MyApp());
  initializeSDK();
}

initializeSDK() {
  SurfboardTTP stoked = SurfboardTTP(
      apiUrl: apiUrl,
      cpocBundleId: cpocBundleId,
      terminalId:
          LocalStorage.posTerminalIdBox?.get(StorageKeys.posTerminalId.name) ??
              '',
      partnerId: partnerId,
      merchantId: merchantId,
      storeId: storeId,
      appId: appId);
  stoked.setAuthToken(authToken: authToken);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SurfboardTTP Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const Testing());
  }
}

class Testing extends StatefulWidget {
  const Testing({super.key});

  @override
  State<Testing> createState() => _TestingState();
}

class _TestingState extends State<Testing> with WidgetsBindingObserver {
  final Terminal terminal = Terminal();
  String transactionId = '';
  RegisterTerminalReturnType registerTerminalReturn =
      const RegisterTerminalReturnType(
          terminalId: '', registrationCodeId: '', entryCode: '');
  @override
  void initState() {
    super.initState();
    String cpocTerminalId =
        LocalStorage.cpocTerminalIdBox?.get(StorageKeys.cpocTerminalId.name) ??
            '';
    if (cpocTerminalId.isEmpty) {
      registerTerminal();
    }
    WidgetsBinding.instance.addObserver(this);
  }

  registerTerminal() {
    try {
      terminal.registerTerminal().then((value) {
        registerTerminalReturn = value;
        if (registerTerminalReturn.entryCode.isNotEmpty) {
          LocalStorage.posTerminalIdBox
              ?.put(StorageKeys.posTerminalId.name, value.terminalId);
          terminal.callCpocForRegistration(registerTerminalReturn.entryCode);
        }
      });
    } catch (e) {
      debugPrint('registration failed $e');
    }
  }

  handleResume() {
    try {
      if (_orderId != 'No order found' && _orderId != 'completed') {
        payment.getTransactionDetails().then((value) {
          setState(() {
            _orderId = 'completed';
            transactionId = value.transactionId;
          });
        });
      } else {
        String cpocTerminalId = LocalStorage.cpocTerminalIdBox
                ?.get(StorageKeys.cpocTerminalId.name) ??
            '';
        if (cpocTerminalId.isEmpty) {
          terminal
              .registerCpoc(registerTerminalReturn.registrationCodeId)
              .then((value) {
            LocalStorage.cpocTerminalIdBox
                ?.put(StorageKeys.cpocTerminalId.name, value);
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Payment payment = Payment();
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    switch (appState) {
      case AppLifecycleState.resumed:
        handleResume();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  LineItem orderLines = LineItem(
    id: '1234',
    quantity: 1,
    name: 'item1',
    itemAmount: ItemAmount(
      regular: 1000,
      total: 1000,
      currency: Currency.sek,
      tax: [
        Tax(
          amount: 100,
          percentage: 10,
          type: TaxType.vat,
        ),
      ],
    ),
  );

  String _orderId = 'No order found';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PaymentSDK',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            Text('current order: $_orderId'),
            if (transactionId.isNotEmpty) Text('transactionId: $transactionId'),
            ElevatedButton(
                onPressed: () {
                  Order order = Order(orderType: OrderType.purchaseOrder);
                  order.addLineItem(orderLines).createOrder().then((value) {
                    setState(() {
                      _orderId = value.orderId;
                    });
                  });
                },
                child: const Text('Create Order')),
            ElevatedButton(
                onPressed: () {
                  payment.initiatePayment(
                    _orderId,
                  );
                },
                child: const Text('Initiate Payment'))
          ],
        ),
      ),
    );
  }
}
