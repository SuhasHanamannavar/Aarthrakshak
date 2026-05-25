import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

const Color _bg = Color(0xFF0A0E27);
const Color _cardBg = Color(0xFF141832);
const Color _gold = Color(0xFFFFD700);
const Color _textSecondary = Color(0xFF8892B0);
const Color _accent = Color(0xFF00E5FF);

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _balanceController = TextEditingController();
  final _incomeController = TextEditingController();
  final _spendController = TextEditingController();
  final _savingsController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _balanceController.dispose();
    _incomeController.dispose();
    _spendController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      'balance': double.tryParse(_balanceController.text.trim()) ?? 0.0,
      'income': double.tryParse(_incomeController.text.trim()) ?? 0.0,
      'spend': double.tryParse(_spendController.text.trim()) ?? 0.0,
      'savings': double.tryParse(_savingsController.text.trim()) ?? 0.0,
    };

    try {
      final res = await ApiService.post('/users/balance', payload);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00C896),
              content: Text('Financial data saved successfully!', style: GoogleFonts.poppins()),
            ),
          );
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        throw Exception('Failed to save data. Payload returned status \${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Error saving data: $e', style: GoogleFonts.poppins()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: _textSecondary),
          prefixIcon: Icon(icon, color: _accent, size: 22),
          filled: true,
          fillColor: _cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _accent.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          'Financial Setup',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: _gold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.account_balance_wallet, size: 64, color: _accent),
                const SizedBox(height: 16),
                Text(
                  'Manual Data Entry',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your current financial overview to initialize your dashboard and AI insights.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: _textSecondary),
                ),
                const SizedBox(height: 32),
                
                _buildTextField(_balanceController, 'Total Account Balance', Icons.account_balance),
                _buildTextField(_incomeController, 'Monthly Income', Icons.payments),
                _buildTextField(_spendController, 'Monthly Spend', Icons.shopping_cart),
                _buildTextField(_savingsController, 'Monthly Savings', Icons.savings),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: _bg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: _bg, strokeWidth: 2.5),
                            ))
                        : Text(
                            'Save & Continue',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
