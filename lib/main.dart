import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const ModawanatApp());
}

class ModawanatApp extends StatelessWidget {
  const ModawanatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مدونات',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const CustomerAccountPage(customerName: 'رياض'),
    );
  }
}

class CustomerAccountPage extends StatefulWidget {
  final String customerName;

  const CustomerAccountPage({super.key, required this.customerName});

  @override
  State<CustomerAccountPage> createState() => _CustomerAccountPageState();
}

class _CustomerAccountPageState extends State<CustomerAccountPage> {
  final TextEditingController _amountController = TextEditingController();
  final String phoneNumber = "772222222"; // رقم العميل

  // دالة إرسال الرسائل النصية المحدثة والمضمونة
  Future<void> _sendSmsNotification(String amount) async {
    if (amount.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال المبلغ أولاً')),
      );
      return;
    }

    final String messageText = "عزيزي ${widget.customerName}، تم تسجيل سحب مبلغ $amount ريال من حسابكم.";
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': messageText,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح تطبيق الرسائل النصية: $e')),
        );
      }
    }
  }

  // دالة إنتاج وتوليد تقرير الـ PDF بدعم خط عربي كامل اتجاه RTL
  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    // تحميل الخطوط العربية تلقائياً لفك المربعات
    final arabicFont = await PdfGoogleFonts.cairoMedium();
    final arabicBoldFont = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl, // تحديد الاتجاه من اليمين لليسار
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'كشف حساب: ${widget.customerName}',
                        style: pw.TextStyle(font: arabicBoldFont, fontSize: 22, color: PdfColors.blue800),
                      ),
                      pw.Text(
                        'التاريخ: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'رقم الهاتف: $phoneNumber',
                  style: pw.TextStyle(font: arabicFont, fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  context: context,
                  cellStyle: pw.TextStyle(font: arabicFont, fontSize: 12),
                  headerStyle: pw.TextStyle(font: arabicBoldFont, fontSize: 13, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                  data: <List<String>>[
                    <String>['نوع العملية', 'المبلغ (ريال)'],
                    <String>['رصيد سابق', '50,000'],
                    <String>['دفعة مسددة', '35,000'],
                    <String>['عملية سحب جديدة', '15,000'],
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'توقيع المحاسب: .....................',
                    style: pw.TextStyle(font: arabicFont, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // معاينة وطباعة/تنزيل الـ PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'كشف_حساب_${widget.customerName}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('كشف حساب: ${widget.customerName}'),
          backgroundColor: Colors.lightBlue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // زر العودة
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // شريط التنقل العلوي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: _generatePdfReport,
                    child: const Text('التقرير الشهري', style: TextStyle(fontSize: 16)),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تسجيل غياب')),
                      );
                    },
                    child: const Text('تسجيل غياب', style: TextStyle(fontSize: 16)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'تسجيل سحبية',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // حقل إدخال المبلغ المسحوب
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المسحوب (ريال)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 25),

              // زر حفظ وإرسال الإشعار
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _sendSmsNotification(_amountController.text),
                  icon: const Icon(Icons.send),
                  label: const Text('SMS حفظ وإرسال إشعار السحب', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
