import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// خدمة ماسح الباركود
class BarcodeScannerService {
  static final BarcodeScannerService _instance =
      BarcodeScannerService._internal();
  factory BarcodeScannerService() => _instance;
  BarcodeScannerService._internal();

  /// فتح الماسح الضوئي وإرجاع الباركود
  static Future<String?> scan(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BarcodeScannerSheet(),
    );
  }

  /// فتح الماسح في صفحة كاملة
  static Future<String?> scanFullScreen(BuildContext context) async {
    return await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerPage(),
      ),
    );
  }
}

/// شيت ماسح الباركود
class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanned = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      child: Column(
        children: [
          // شريط العنوان
          _buildHeader(context),

          // منطقة المسح
          Expanded(
            child: Stack(
              children: [
                // الكاميرا
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),

                // إطار المسح
                _buildScanFrame(),

                // التعليمات
                _buildInstructions(context),
              ],
            ),
          ),

          // أزرار التحكم
          _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'مسح الباركود',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textLight),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFrame() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondary, width: 3),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Stack(
          children: [
            // الزوايا
            ..._buildCorners(),
            // خط المسح المتحرك
            _buildScanLine(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const cornerSize = 30.0;
    const cornerWidth = 4.0;
    const color = AppColors.primary;

    return [
      // أعلى يسار
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),
      // أعلى يمين
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),
      // أسفل يسار
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),
      // أسفل يمين
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),
    ];
  }

  Widget _buildScanLine() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Positioned(
          top: value * 240,
          left: 10,
          right: 10,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Text(
        'وجّه الكاميرا نحو الباركود',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textLight.withOpacity(0.8),
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      color: AppColors.primary,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // زر الفلاش
            _buildControlButton(
              context: context,
              icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
              label: 'الفلاش',
              isActive: _isTorchOn,
              onTap: _toggleTorch,
            ),
            // زر الإدخال اليدوي
            _buildControlButton(
              context: context,
              icon: Icons.keyboard,
              label: 'يدوي',
              onTap: () => _showManualInput(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.secondary
                  : AppColors.secondary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textLight,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textLight.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isScanned = true);

    Navigator.pop(context, barcode);
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  void _showManualInput(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const ManualBarcodeDialog(),
    );

    if (result != null && result.isNotEmpty && mounted) {
      Navigator.pop(context, result);
    }
  }
}

/// صفحة ماسح الباركود (شاشة كاملة)
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanned = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('مسح الباركود'),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? AppColors.secondary : AppColors.textLight,
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          // الكاميرا
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // إطار المسح
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondary, width: 3),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          ),

          // التعليمات
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'وجّه الكاميرا نحو الباركود',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textLight.withOpacity(0.8),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),
                TextButton.icon(
                  onPressed: () => _showManualInput(context),
                  icon: const Icon(Icons.keyboard, color: AppColors.secondary),
                  label: const Text(
                    'إدخال يدوي',
                    style: TextStyle(color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isScanned = true);
    Navigator.pop(context, barcode);
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  void _showManualInput(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const ManualBarcodeDialog(),
    );

    if (result != null && result.isNotEmpty && mounted) {
      Navigator.pop(context, result);
    }
  }
}

/// حوار الإدخال اليدوي للباركود
class ManualBarcodeDialog extends StatefulWidget {
  const ManualBarcodeDialog({super.key});

  @override
  State<ManualBarcodeDialog> createState() => _ManualBarcodeDialogState();
}

class _ManualBarcodeDialogState extends State<ManualBarcodeDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      title: Text(
        'إدخال الباركود يدوياً',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'رقم الباركود',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintText: 'أدخل رقم الباركود',
            hintStyle: const TextStyle(color: AppColors.textHint),
            prefixIcon: const Icon(Icons.qr_code, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'أدخل رقم الباركود';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'إلغاء',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
          ),
          child: const Text('بحث'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }
}
