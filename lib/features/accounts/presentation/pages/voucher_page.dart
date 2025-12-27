import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة السندات
class VoucherPage extends StatefulWidget {
  final String type; // 'receipt' or 'payment'

  const VoucherPage({super.key, this.type = 'receipt'});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _paymentMethod = 'CASH';
  int? _selectedPartyId;

  bool get _isReceipt => widget.type == 'receipt';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReceipt ? 'سند قبض' : 'سند صرف'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // اختيار العميل/المورد
            InkWell(
              onTap: _selectParty,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _isReceipt ? 'العميل' : 'المورد',
                  prefixIcon:
                      Icon(_isReceipt ? Icons.person : Icons.local_shipping),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _selectedPartyId != null
                      ? '${_isReceipt ? 'عميل' : 'مورد'} $_selectedPartyId'
                      : 'اختر ${_isReceipt ? 'العميل' : 'المورد'}',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // المبلغ
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ *',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'ر.س',
              ),
            ),
            const SizedBox(height: 16),

            // طريقة الدفع
            const Text('طريقة الدفع'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('نقدي'),
                    value: 'CASH',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() => _paymentMethod = value!);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('شبكة'),
                    value: 'CARD',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() => _paymentMethod = value!);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ملاحظات
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                alignLabelWithHint: true,
              ),
            ),
            const Spacer(),

            // زر الحفظ
            PrimaryButton(
              text: 'حفظ السند',
              icon: Icons.save,
              color: _isReceipt ? AppColors.success : AppColors.error,
              onPressed: _saveVoucher,
            ),
          ],
        ),
      ),
    );
  }

  void _selectParty() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر ${_isReceipt ? 'العميل' : 'المورد'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('${_isReceipt ? 'عميل' : 'مورد'} ${index + 1}'),
                    subtitle: Text('الرصيد: ${index * 100} ر.س'),
                    onTap: () {
                      setState(() => _selectedPartyId = index + 1);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveVoucher() {
    if (_selectedPartyId == null) {
      showSnackBar(context, 'الرجاء اختيار ${_isReceipt ? 'العميل' : 'المورد'}',
          isError: true);
      return;
    }
    if (_amountController.text.isEmpty) {
      showSnackBar(context, 'الرجاء إدخال المبلغ', isError: true);
      return;
    }

    // TODO: حفظ السند
    showSnackBar(context, 'تم حفظ السند بنجاح');
    Navigator.pop(context);
  }
}
