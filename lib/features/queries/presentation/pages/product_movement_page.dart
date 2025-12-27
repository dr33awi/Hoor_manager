import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة حركة المنتج
class ProductMovementPage extends StatefulWidget {
  const ProductMovementPage({super.key});

  @override
  State<ProductMovementPage> createState() => _ProductMovementPageState();
}

class _ProductMovementPageState extends State<ProductMovementPage> {
  final _searchController = TextEditingController();
  String? _selectedProductName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حركة المنتج'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // البحث عن المنتج
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            child: CustomSearchField(
              controller: _searchController,
              hintText: 'ابحث عن منتج...',
              onScan: () {},
              onChanged: (value) {
                if (value.length >= 2) {
                  setState(() => _selectedProductName = 'منتج تجريبي');
                }
              },
            ),
          ),

          // معلومات المنتج المختار
          if (_selectedProductName != null)
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              color: AppColors.surfaceVariant,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProductName!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'الكمية الحالية: 50',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // قائمة الحركات
          if (_selectedProductName != null)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.paddingSM),
                itemCount: 20,
                itemBuilder: (context, index) {
                  final isIn = index % 2 == 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIn
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        child: Icon(
                          isIn ? Icons.add : Icons.remove,
                          color: isIn ? AppColors.success : AppColors.error,
                        ),
                      ),
                      title: Text(isIn ? 'فاتورة شراء' : 'فاتورة مبيعات'),
                      subtitle: Text(
                          '${DateTime.now().subtract(Duration(days: index)).toString().substring(0, 10)}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isIn ? '+' : '-'}${index + 5}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIn ? AppColors.success : AppColors.error,
                            ),
                          ),
                          Text(
                            'الرصيد: ${50 + (isIn ? (index + 5) : -(index + 5))}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('ابحث عن منتج لعرض حركته'),
              ),
            ),
        ],
      ),
    );
  }
}
