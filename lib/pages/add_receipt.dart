import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/receipt.dart';

class AddReceiptScreen extends StatefulWidget {
  final String? scannedText;

  const AddReceiptScreen({super.key, this.scannedText});

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _storeNameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If we have scanned text, try to extract data
    if (widget.scannedText != null) {
      _parseScannedText(widget.scannedText!);
    }
  }

  void _parseScannedText(String text) {
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    // 1. Find store name
    // Priority 1: Find line containing "A.Ş." (company name)
    for (int i = 0; i < (lines.length < 10 ? lines.length : 10); i++) {
      final line = lines[i];
      if (line.contains('A.Ş.') || line.contains('A.S.')) {
        _storeNameController.text = line;
        break;
      }
    }

    // Priority 2: First meaningful line
    if (_storeNameController.text.isEmpty && lines.isNotEmpty) {
      for (int i = 0; i < (lines.length < 3 ? lines.length : 3); i++) {
        final line = lines[i];
        if (line.length > 5 && !RegExp(r'^\d+$').hasMatch(line) && !line.toLowerCase().contains('mgz')) {
          _storeNameController.text = line;
          break;
        }
      }
    }

    // 2. Find TOPLAM/Toplam (Total) and get amount
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineUpper = line.toUpperCase();

      // Excluded: TOPKDV, Toplam KDV (Total VAT)
      final isToplamLine = lineUpper.contains('TOPLAM') || line.contains('Toplam');
      final isExcluded = lineUpper.contains('TOPKDV') || lineUpper.contains('TOPLAM KDV') || line.contains('Toplam KDV');

      if (isToplamLine && !isExcluded) {
        // Get number after * symbol on same line
        final starMatch = RegExp(r'\*\s*([\d.,]+)').firstMatch(line);
        if (starMatch != null) {
          final amountStr = starMatch.group(1)!;
          final cleanAmount = amountStr.replaceAll('.', '').replaceAll(',', '.');
          final parsed = double.tryParse(cleanAmount);
          if (parsed != null && parsed > 0) {
            _totalAmountController.text = parsed.toStringAsFixed(2);
            break;
          }
        }

        // Check for number on same line (e.g., "Toplam 1113,35")
        final numMatches = RegExp(r'[\d.,]+').allMatches(line).toList();
        if (numMatches.isNotEmpty) {
          for (int j = numMatches.length - 1; j >= 0; j--) {
            final amountStr = numMatches[j].group(0)!;
            final cleanAmount = amountStr.replaceAll('.', '').replaceAll(',', '.');
            final parsed = double.tryParse(cleanAmount);
            if (parsed != null && parsed > 10) { // Must be greater than 10
              _totalAmountController.text = parsed.toStringAsFixed(2);
              break;
            }
          }
          if (_totalAmountController.text.isNotEmpty) break;
        }

        // If no amount on same line, check next line
        if (_totalAmountController.text.isEmpty && i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          final nextStarMatch = RegExp(r'\*\s*([\d.,]+)').firstMatch(nextLine);
          if (nextStarMatch != null) {
            final amountStr = nextStarMatch.group(1)!;
            final cleanAmount = amountStr.replaceAll('.', '').replaceAll(',', '.');
            final parsed = double.tryParse(cleanAmount);
            if (parsed != null && parsed > 0) {
              _totalAmountController.text = parsed.toStringAsFixed(2);
              break;
            }
          } else {
            final numMatch = RegExp(r'([\d.,]+)').firstMatch(nextLine);
            if (numMatch != null) {
              final amountStr = numMatch.group(1)!;
              final cleanAmount = amountStr.replaceAll('.', '').replaceAll(',', '.');
              final parsed = double.tryParse(cleanAmount);
              if (parsed != null && parsed > 10) {
                _totalAmountController.text = parsed.toStringAsFixed(2);
                break;
              }
            }
          }
        }
      }
    }

    // 3. Find TARİH/Tarih (Date) line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineUpper = line.toUpperCase();

      if (lineUpper.contains('TARİH') || lineUpper.contains('TARIH')) {
        // Check for date on same line
        var dateMatch = RegExp(r'(\d{2})\.(\d{2})\.(\d{4})').firstMatch(line);
        if (dateMatch != null) {
          final day = int.parse(dateMatch.group(1)!);
          final month = int.parse(dateMatch.group(2)!);
          final year = int.parse(dateMatch.group(3)!);
          setState(() {
            _selectedDate = DateTime(year, month, day);
          });
          break;
        }
        // Check next line for date
        if (i + 1 < lines.length) {
          dateMatch = RegExp(r'(\d{2})\.(\d{2})\.(\d{4})').firstMatch(lines[i + 1]);
          if (dateMatch != null) {
            final day = int.parse(dateMatch.group(1)!);
            final month = int.parse(dateMatch.group(2)!);
            final year = int.parse(dateMatch.group(3)!);
            setState(() {
              _selectedDate = DateTime(year, month, day);
            });
            break;
          }
        }
      }
    }

    // If date still not found, search all lines for date format
    if (_selectedDate == DateTime.now()) {
      for (int i = 0; i < lines.length; i++) {
        final dateMatch = RegExp(r'(\d{2})\.(\d{2})\.(\d{4})').firstMatch(lines[i]);
        if (dateMatch != null) {
          final day = int.parse(dateMatch.group(1)!);
          final month = int.parse(dateMatch.group(2)!);
          final year = int.parse(dateMatch.group(3)!);
          setState(() {
            _selectedDate = DateTime(year, month, day);
          });
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _totalAmountController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = CreateReceiptRequest(
      storeName: _storeNameController.text.trim(),
      date: _selectedDate,
      totalAmount: double.parse(_totalAmountController.text.replaceAll(',', '.')),
      tags: _tagsController.text.trim().isNotEmpty ? _tagsController.text.trim() : null,
    );

    final response = await _apiService.createReceipt(request);

    setState(() => _isLoading = false);

    if (response.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fiş başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Fiş eklenirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yeni Fiş Ekle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Scanned text preview (if available)
            if (widget.scannedText != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.document_scanner, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Taranan Metin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.scannedText!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Form
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store name
                    _buildLabel('Mağaza Adı'),
                    TextFormField(
                      controller: _storeNameController,
                      decoration: _inputDecoration('Örn: Migros, A101, BIM...'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mağaza adı gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date
                    _buildLabel('Tarih'),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total amount
                    _buildLabel('Toplam Tutar (₺)'),
                    TextFormField(
                      controller: _totalAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('0.00'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tutar gerekli';
                        }
                        final amount = double.tryParse(value.replaceAll(',', '.'));
                        if (amount == null || amount <= 0) {
                          return 'Geçerli bir tutar girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Tags
                    _buildLabel('Etiketler (isteğe bağlı)'),
                    TextFormField(
                      controller: _tagsController,
                      decoration: _inputDecoration('Örn: Market, Haftalık, Organik...'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Etiketleri virgülle ayırın',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveReceipt,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CFA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

