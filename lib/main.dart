import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ModawanatApp());
}

class ModawanatApp extends StatelessWidget {
  const ModawanatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مدونة الحسابات',
      theme: ThemeData(
        primaryColor: const Color(0xFF00A2E8),
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        useMaterial3: false,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SetupOrLoginRouter(),
      ),
    );
  }
}

class SetupOrLoginRouter extends StatefulWidget {
  const SetupOrLoginRouter({super.key});

  @override
  State<SetupOrLoginRouter> createState() => _SetupOrLoginRouterState();
}

class _SetupOrLoginRouterState extends State<SetupOrLoginRouter> {
  bool isLoading = true;
  String? storeName;
  String adminPin = '1234';
  String supervisorPin = '0000';

  @override
  void initState() {
    super.initState();
    _loadSetupData();
  }

  Future<void> _loadSetupData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      storeName = prefs.getString('storeName');
      adminPin = prefs.getString('adminPin') ?? '1234';
      supervisorPin = prefs.getString('supervisorPin') ?? '0000';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (storeName == null || storeName!.isEmpty) {
      return StoreSetupScreen(
        onSetupComplete: (name, aPin, sPin) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('storeName', name);
          await prefs.setString('adminPin', aPin);
          await prefs.setString('supervisorPin', sPin);

          setState(() {
            storeName = name;
            adminPin = aPin;
            supervisorPin = sPin;
          });
        },
      );
    } else {
      return LoginScreen(
        storeName: storeName!,
        adminPin: adminPin,
        supervisorPin: supervisorPin,
        onResetStore: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('storeName');
          setState(() {
            storeName = null;
          });
        },
        onUpdatePins: (newStore, newAdmin, newSup) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('storeName', newStore);
          await prefs.setString('adminPin', newAdmin);
          await prefs.setString('supervisorPin', newSup);

          setState(() {
            storeName = newStore;
            adminPin = newAdmin;
            supervisorPin = newSup;
          });
        },
      );
    }
  }
}

class StoreSetupScreen extends StatefulWidget {
  final Function(String, String, String) onSetupComplete;

  const StoreSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  final _storeController = TextEditingController();
  final _adminPinController = TextEditingController(text: '1234');
  final _supPinController = TextEditingController(text: '0000');

  @override
  void dispose() {
    _storeController.dispose();
    _adminPinController.dispose();
    _supPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد المنشأة لأول مرة'),
        backgroundColor: const Color(0xFF00A2E8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.storefront, size: 70, color: Color(0xFF00A2E8)),
            const SizedBox(height: 15),
            const Text(
              'مرحباً بك! يرجى تهيئة بيانات المحل أولاً',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _storeController,
              decoration: const InputDecoration(
                labelText: 'اسم المحل / المنشأة (مثال: معرض كاجوال)',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _adminPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'تعيين كلمة مرور (المدير الرئيسي)',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _supPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'تعيين كلمة مرور (المشرف / مدير العمال)',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A2E8),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                if (_storeController.text.isNotEmpty &&
                    _adminPinController.text.isNotEmpty &&
                    _supPinController.text.isNotEmpty) {
                  widget.onSetupComplete(
                    _storeController.text,
                    _adminPinController.text,
                    _supPinController.text,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء كافة البيانات المطلوبة')),
                  );
                }
              },
              child: const Text('حفظ وبدء الاستخدام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String storeName;
  final String adminPin;
  final String supervisorPin;
  final VoidCallback onResetStore;
  final Function(String, String, String) onUpdatePins;

  const LoginScreen({
    super.key,
    required this.storeName,
    required this.adminPin,
    required this.supervisorPin,
    required this.onResetStore,
    required this.onUpdatePins,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'المدير الرئيسي';
  final TextEditingController _passController = TextEditingController();

  void _login() {
    bool isAdmin = selectedRole == 'المدير الرئيسي' && _passController.text == widget.adminPin;
    bool isSupervisor = selectedRole == 'مدير العمال' && _passController.text == widget.supervisorPin;

    if (isAdmin || isSupervisor) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userRole: selectedRole,
            storeName: widget.storeName,
            adminPin: widget.adminPin,
            supervisorPin: widget.supervisorPin,
            onSettingsUpdated: widget.onUpdatePins,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور خاطئة!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF00A2E8),
                child: Icon(Icons.account_balance_wallet, size: 45, color: Colors.white),
              ),
              const SizedBox(height: 15),
              Text(
                widget.storeName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00A2E8)),
              ),
              const Text('نظام إدارة العمال والحسابات', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 25),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('دخول كـ : المدير الرئيسي'),
                        value: 'المدير الرئيسي',
                        groupValue: selectedRole,
                        activeColor: const Color(0xFF00A2E8),
                        onChanged: (val) => setState(() => selectedRole = val!),
                      ),
                      RadioListTile<String>(
                        title: const Text('دخول كـ : مدير العمال (المشرف)'),
                        value: 'مدير العمال',
                        groupValue: selectedRole,
                        activeColor: const Color(0xFF00A2E8),
                        onChanged: (val) => setState(() => selectedRole = val!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رمز المرور (PIN)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A2E8),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _login,
                child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userRole;
  final String storeName;
  final String adminPin;
  final String supervisorPin;
  final Function(String, String, String) onSettingsUpdated;

  const HomeScreen({
    super.key,
    required this.userRole,
    required this.storeName,
    required this.adminPin,
    required this.supervisorPin,
    required this.onSettingsUpdated,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _currentStoreName;
  late String _adminPin;
  late String _supervisorPin;
  String linkedEmail = 'غير مربوط بأي إيميل';

  List<Map<String, dynamic>> workers = [];

  @override
  void initState() {
    super.initState();
    _currentStoreName = widget.storeName;
    _adminPin = widget.adminPin;
    _supervisorPin = widget.supervisorPin;
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? workersData = prefs.getString('workers_list');
    
    if (workersData != null) {
      List<dynamic> decoded = jsonDecode(workersData);
      setState(() {
        workers = decoded.map((e) {
          var w = Map<String, dynamic>.from(e);
          w['totalWithdrawals'] ??= 0.0;
          w['absencesWithPermission'] ??= 0;
          w['absencesWithoutPermission'] ??= 0;
          return w;
        }).toList();
      });
    } else {
      setState(() {
        workers = [];
      });
      _saveWorkers();
    }
  }

  Future<void> _saveWorkers() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(workers);
    await prefs.setString('workers_list', encoded);
  }

  String _calculateTotalBalance() {
    double total = 0;
    for (var worker in workers) {
      double initialAmount = double.tryParse(worker['amount'].toString().replaceAll(',', '')) ?? 0;
      double withdrawals = (worker['totalWithdrawals'] ?? 0).toDouble();
      total += (initialAmount - withdrawals);
    }
    return total.toStringAsFixed(0);
  }

  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة عامل جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العامل', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 10),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 10),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الرصيد الابتدائي/الراتب (ريال)', prefixIcon: Icon(Icons.money))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A2E8)),
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                setState(() {
                  workers.add({
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'amount': amountController.text.isEmpty ? '0' : amountController.text,
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'totalWithdrawals': 0.0,
                    'absencesWithPermission': 0,
                    'absencesWithoutPermission': 0,
                  });
                });
                _saveWorkers();
                Navigator.pop(ctx);
                _showSnackbar('تمت إضافة العامل [${nameController.text}] بنجاح!');
              } else {
                _showSnackbar('يرجى ملء الاسم ورقم الهاتف أولاً');
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditWorkerDialog(int index) {
    final worker = workers[index];
    final nameController = TextEditingController(text: worker['name']);
    final phoneController = TextEditingController(text: worker['phone']);
    final amountController = TextEditingController(text: worker['amount'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل بيانات العامل'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العامل', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 10),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 10),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الرصيد الابتدائي (ريال)', prefixIcon: Icon(Icons.money))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A2E8)),
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                setState(() {
                  workers[index]['name'] = nameController.text;
                  workers[index]['phone'] = phoneController.text;
                  workers[index]['amount'] = amountController.text.isEmpty ? '0' : amountController.text;
                });
                _saveWorkers();
                Navigator.pop(ctx);
                _showSnackbar('تم تعديل بيانات العامل بنجاح!');
              } else {
                _showSnackbar('يرجى ملء كافة الحقول');
              }
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  void _deleteWorker(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.red)),
        content: Text('هل أنت متأكد من أنك تريد حذف حساب العامل [${workers[index]['name']}]؟ لن يمكنك التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                workers.removeAt(index);
              });
              _saveWorkers();
              Navigator.pop(ctx);
              _showSnackbar('تم حذف العامل نهائياً.');
            },
            child: const Text('حذف العامل'),
          ),
        ],
      ),
    );
  }

  void _showStoreSettingsDialog() {
    final storeController = TextEditingController(text: _currentStoreName);
    final adminPinController = TextEditingController(text: _adminPin);
    final supPinController = TextEditingController(text: _supervisorPin);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل بيانات المنشأة وكلمات المرور'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: storeController, decoration: const InputDecoration(labelText: 'اسم المحل / المنشأة', prefixIcon: Icon(Icons.store))),
              const SizedBox(height: 10),
              TextField(controller: adminPinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رمز مرور المدير (PIN)', prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 10),
              TextField(controller: supPinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رمز مرور المشرف (PIN)', prefixIcon: Icon(Icons.lock_outline))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A2E8)),
            onPressed: () {
              if (storeController.text.isNotEmpty && adminPinController.text.isNotEmpty) {
                setState(() {
                  _currentStoreName = storeController.text;
                  _adminPin = adminPinController.text;
                  _supervisorPin = supPinController.text;
                });
                widget.onSettingsUpdated(_currentStoreName, _adminPin, _supervisorPin);
                Navigator.pop(ctx);
                _showSnackbar('تم حفظ التعديلات بنجاح!');
              } else {
                _showSnackbar('يرجى ملء الحقول المطلوبة');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showGoogleDriveDialog(bool isUpload) {
    final emailController = TextEditingController(text: linkedEmail != 'غير مربوط بأي إيميل' ? linkedEmail : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isUpload ? Icons.cloud_upload : Icons.cloud_download, color: const Color(0xFF00A2E8)),
            const SizedBox(width: 8),
            Text(isUpload ? 'حفظ نسخة في Google Drive' : 'استعادة نسخة من Google Drive'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('أدخل إيميل جوجل (Gmail) المرتبط بالحسابات:'),
            const SizedBox(height: 10),
            TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'إيميل Gmail الخاص بك', hintText: 'example@gmail.com', prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A2E8)),
            onPressed: () {
              if (emailController.text.contains('@')) {
                setState(() {
                  linkedEmail = emailController.text;
                });
                Navigator.pop(ctx);
                _showSnackbar(isUpload ? 'تم رفع النسخة الاحتياطية لـ [$_currentStoreName] إلى: $linkedEmail' : 'تم استعادة البيانات بنجاح لـ [$_currentStoreName] من: $linkedEmail');
              } else {
                _showSnackbar('يرجى إدخال إيميل Gmail صحيح');
              }
            },
            child: Text(isUpload ? 'حفظ الآن' : 'استعادة الآن'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.black87));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00A2E8), Color(0xFF0080FF)])),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_currentStoreName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: Text('المستخدم الحالي: ${widget.userRole}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(height: 6),
                  Text('الإيميل: $linkedEmail', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            if (widget.userRole == 'المدير الرئيسي') ...[
              ListTile(leading: const Icon(Icons.settings, color: Colors.orange), title: const Text('إعدادات المنشأة وكلمات المرور'), onTap: () { Navigator.pop(context); _showStoreSettingsDialog(); }),
              ListTile(leading: const Icon(Icons.cloud_upload, color: Colors.blue), title: const Text('حفظ نسخة احتياطية (Google Drive)'), onTap: () { Navigator.pop(context); _showGoogleDriveDialog(true); }),
              ListTile(leading: const Icon(Icons.cloud_download, color: Colors.green), title: const Text('استعادة النسخة (Google Drive)'), onTap: () { Navigator.pop(context); _showGoogleDriveDialog(false); }),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('تسجيل الخروج'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen(storeName: _currentStoreName, adminPin: _adminPin, supervisorPin: _supervisorPin, onResetStore: () {}, onUpdatePins: widget.onSettingsUpdated)));
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A2E8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentStoreName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('العمال - الحساب: ${widget.userRole}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final item = workers[index];
                
                double initialAmount = double.tryParse(item['amount'].toString()) ?? 0;
                double withdrawals = (item['totalWithdrawals'] ?? 0).toDouble();
                double remaining = initialAmount - withdrawals;
                bool isUp = remaining >= 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkerDetailsPage(
                            worker: item,
                            role: widget.userRole,
                            storeName: _currentStoreName,
                            onWorkerUpdated: (updatedWorker) {
                              setState(() {
                                int idx = workers.indexWhere((w) => w['id'] == updatedWorker['id']);
                                if (idx != -1) workers[idx] = updatedWorker;
                              });
                              _saveWorkers();
                            },
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: isUp ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(6)),
                      child: Icon(isUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: isUp ? Colors.green[700] : Colors.red[700]),
                    ),
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('رقم الهاتف: ${item['phone']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${remaining.toStringAsFixed(0)} ريال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isUp ? Colors.green[800] : Colors.red[800])),
                        if (widget.userRole == 'المدير الرئيسي') 
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'edit') _showEditWorkerDialog(index);
                              else if (value == 'delete') _deleteWorker(index);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text('تعديل بيانات العامل')])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('حذف حساب العامل', style: TextStyle(color: Colors.red))])),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: const Color(0xFFCFD8DC),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (widget.userRole == 'المدير الرئيسي')
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFF00A2E8), borderRadius: BorderRadius.circular(6)),
                    child: IconButton(icon: const Icon(Icons.person_add, color: Colors.white), onPressed: _showAddWorkerDialog),
                  ),
                const SizedBox(width: 10),
                Expanded(child: Text('الرصيد الإجمالي: ${_calculateTotalBalance()} ريال', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkerDetailsPage extends StatefulWidget {
  final Map<String, dynamic> worker;
  final String role;
  final String storeName;
  final Function(Map<String, dynamic>) onWorkerUpdated;

  const WorkerDetailsPage({
    super.key,
    required this.worker,
    required this.role,
    required this.storeName,
    required this.onWorkerUpdated,
  });

  @override
  State<WorkerDetailsPage> createState() => _WorkerDetailsPageState();
}

class _WorkerDetailsPageState extends State<WorkerDetailsPage> {
  final TextEditingController _withdrawController = TextEditingController();
  final TextEditingController _absenceReasonController = TextEditingController();
  String _absenceType = 'بإذن';

  @override
  void dispose() {
    _withdrawController.dispose();
    _absenceReasonController.dispose();
    super.dispose();
  }

  Future<void> _sendDirectSms(String phoneNumber, String messageText) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber, queryParameters: <String, String>{'body': messageText});
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء فتح تطبيق الرسائل النصية')));
    }
  }

  Future<void> _generatePdfReport(double remainingBalance) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoMedium();
    final arabicBoldFont = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 0, child: pw.Text('${widget.storeName} - تقرير كشف حساب شهري', style: pw.TextStyle(font: arabicBoldFont, fontSize: 18, color: PdfColors.blue800))),
                pw.SizedBox(height: 10),
                pw.Text('اسم العامل: ${widget.worker['name']}', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                pw.Text('رقم الهاتف: ${widget.worker['phone']}', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  context: context,
                  cellStyle: pw.TextStyle(font: arabicFont, fontSize: 12),
                  headerStyle: pw.TextStyle(font: arabicBoldFont, fontSize: 13, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                  data: <List<String>>[
                    ['البيان', 'التفاصيل / القيمة'],
                    ['أيام الغياب (بإذن)', '${widget.worker['absencesWithPermission'] ?? 0} أيام'],
                    ['أيام الغياب (بدون إذن)', '${widget.worker['absencesWithoutPermission'] ?? 0} أيام'],
                    ['إجمالي السحبيات والخصومات', '${(widget.worker['totalWithdrawals'] ?? 0).toStringAsFixed(0)} ريال'],
                    ['المبلغ المتبقي الصافي للشهر', '${remainingBalance.toStringAsFixed(0)} ريال'],
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text('المنشأة: ${widget.storeName}', style: pw.TextStyle(font: arabicBoldFont, fontSize: 12)),
                pw.Text('المسؤول عن التقرير: ${widget.role}', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'تقرير_${widget.worker['name']}.pdf',
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.black87));
  }

  @override
  Widget build(BuildContext context) {
    int absWithPerm = widget.worker['absencesWithPermission'] ?? 0;
    int absNoPerm = widget.worker['absencesWithoutPermission'] ?? 0;
    double initialAmount = double.tryParse(widget.worker['amount'].toString()) ?? 0;
    double totalWithdrawals = (widget.worker['totalWithdrawals'] ?? 0).toDouble();
    double remainingBalance = initialAmount - totalWithdrawals;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF00A2E8),
          title: Text('كشف حساب: ${widget.worker['name']}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'تسجيل سحبية'),
              Tab(text: 'تسجيل غياب'),
              Tab(text: 'التقرير الشهري'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _withdrawController,
                    decoration: const InputDecoration(labelText: 'المبلغ المسحوب (ريال)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A2E8), minimumSize: const Size.fromHeight(45)),
                    icon: const Icon(Icons.send),
                    label: const Text('حفظ وإرسال إشعار السحب SMS'),
                    onPressed: () {
                      double amount = double.tryParse(_withdrawController.text) ?? 0;
                      if (amount > 0) {
                        widget.worker['totalWithdrawals'] = totalWithdrawals + amount;
                        widget.onWorkerUpdated(widget.worker);

                        String msg = '[${widget.storeName}] تم تسجيل سحبية بمبلغ ${_withdrawController.text} ريال للعامل [${widget.worker['name']}] بواسطة [${widget.role}].';
                        _sendDirectSms(widget.worker['phone'], msg);
                        _withdrawController.clear();
                        _showSnackbar('تم حفظ السحبية بنجاح وخصمها من الرصيد');
                        setState(() {});
                      } else {
                        _showSnackbar('يرجى كتابة مبلغ صحيح أولاً');
                      }
                    },
                  )
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('نوع الغياب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    child: Column(
                      children: [
                        RadioListTile<String>(title: const Text('غياب بإذن'), value: 'بإذن', groupValue: _absenceType, activeColor: const Color(0xFF00A2E8), onChanged: (val) => setState(() => _absenceType = val!)),
                        RadioListTile<String>(title: const Text('غياب بدون إذن'), value: 'بدون إذن', groupValue: _absenceType, activeColor: Colors.red, onChanged: (val) => setState(() => _absenceType = val!)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _absenceReasonController,
                    decoration: const InputDecoration(labelText: 'السبب والتفاصيل (مثال: مريض، سفر...)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size.fromHeight(45)),
                    icon: const Icon(Icons.sms),
                    label: const Text('حفظ وإرسال إشعار الغياب SMS'),
                    onPressed: () {
                      if (_absenceReasonController.text.isNotEmpty) {
                        if (_absenceType == 'بإذن') {
                          widget.worker['absencesWithPermission'] = absWithPerm + 1;
                        } else {
                          widget.worker['absencesWithoutPermission'] = absNoPerm + 1;
                        }
                        widget.onWorkerUpdated(widget.worker);

                        String msg = '[${widget.storeName}] تم تسجيل غياب [$_absenceType] للعامل [${widget.worker['name']}]. السبب: ${_absenceReasonController.text}. المسجل: [${widget.role}].';
                        _sendDirectSms(widget.worker['phone'], msg);
                        _absenceReasonController.clear();
                        _showSnackbar('تم حفظ يوم الغياب بنجاح');
                        setState(() {});
                      } else {
                        _showSnackbar('يرجى كتابة سبب الغياب أولاً');
                      }
                    },
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.event_available, color: Colors.blue),
                      title: const Text('إجمالي الغياب (بإذن)'),
                      trailing: Text('$absWithPerm أيام', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.event_busy, color: Colors.red),
                      title: const Text('إجمالي الغياب (بدون إذن)'),
                      trailing: Text('$absNoPerm أيام', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.money_off, color: Colors.orange),
                      title: const Text('إجمالي الخصومات والسحبيات'),
                      trailing: Text('${totalWithdrawals.toStringAsFixed(0)} ريال', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                      title: const Text('باقي الحساب النهائي للشهر'),
                      trailing: Text('${remainingBalance.toStringAsFixed(0)} ريال', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A2E8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.sms),
                          label: const Text('إرسال SMS'),
                          onPressed: () {
                            String msg = '[${widget.storeName}] التقرير الشهري للعامل [${widget.worker['name']}]: إجمالي سحبياتك (${totalWithdrawals.toStringAsFixed(0)})، باقي حسابك النهائي هو ${remainingBalance.toStringAsFixed(0)} ريال.';
                            _sendDirectSms(widget.worker['phone'], msg);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('تصدير PDF'),
                          onPressed: () {
                            _generatePdfReport(remainingBalance);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
