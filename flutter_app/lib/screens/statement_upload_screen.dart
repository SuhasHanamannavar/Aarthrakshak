import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

const Color _bg = Color(0xFF0A0E27);
const Color _cardBg = Color(0xFF141832);
const Color _gold = Color(0xFFFFD700);
const Color _textSecondary = Color(0xFF8892B0);
const Color _accent = Color(0xFF00E5FF);
const Color _spenderAccent = Color(0xFFFF6B6B);

class StatementUploadScreen extends StatefulWidget {
  const StatementUploadScreen({super.key});

  @override
  State<StatementUploadScreen> createState() => _StatementUploadScreenState();
}

class _StatementUploadScreenState extends State<StatementUploadScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isUploading = false;
  bool _isConfirming = false;

  Map<String, dynamic>? _parsedSummary;
  List<dynamic>? _parsedTransactions;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _parsedSummary = null;
        _parsedTransactions = null;
      });
    }
  }

  Future<void> _uploadStatement() async {
    if (_selectedFilePath == null) return;
    setState(() => _isUploading = true);
    
    try {
      final streamedRes = await ApiService.uploadPdf('/statements/upload', _selectedFilePath!, 'file');
      final res = await streamedRes.stream.bytesToString();
      
      if (streamedRes.statusCode == 200 || streamedRes.statusCode == 201) {
        final data = jsonDecode(res) as Map<String, dynamic>;
        setState(() {
          _parsedTransactions = data['transactions'] as List<dynamic>? ?? [];
          _parsedSummary = data['summary'] as Map<String, dynamic>? ?? {};
        });
      } else {
        throw Exception('Server rejected the PDF with status \${streamedRes.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error analyzing statement: $e', style: GoogleFonts.poppins())),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _confirmData() async {
    if (_parsedTransactions == null) return;
    setState(() => _isConfirming = true);
    try {
      final payload = {'transactions': _parsedTransactions};
      final res = await ApiService.post('/statements/confirm', payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: const Color(0xFF00C896), content: Text('Data seamlessly synced to Supabase!', style: GoogleFonts.poppins())),
          );
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error saving to Supabase.', style: GoogleFonts.poppins())),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text('Statement Upload', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: _gold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUploadCard(),
              const SizedBox(height: 24),
              if (_isUploading)
                const Column(
                  children: [
                    SizedBox(height: 40),
                    CircularProgressIndicator(color: _accent),
                    SizedBox(height: 16),
                    Text('Groq AI is securely parsing your statement...', style: TextStyle(color: _textSecondary)),
                  ],
                ),
              if (!_isUploading && _parsedTransactions != null) ...[
                _buildSummaryCard(),
                const SizedBox(height: 24),
                Text('Detected Transactions (\${_parsedTransactions!.length})', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                _buildTransactionsList(),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isConfirming ? null : _confirmData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C896),
                      foregroundColor: _bg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isConfirming 
                      ? const Center(child: SizedBox(width:24, height:24, child: CircularProgressIndicator(color: _bg)))
                      : Text('Confirm & Save to Supabase', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.picture_as_pdf, size: 56, color: _selectedFileName != null ? const Color(0xFF00C896) : _textSecondary),
          const SizedBox(height: 16),
          Text(
            _selectedFileName ?? 'Select your PDF Bank Statement',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (_isUploading || _isConfirming) ? null : _pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(_selectedFileName == null ? 'Browse Files' : 'Change File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent.withValues(alpha: 0.1),
              foregroundColor: _accent,
              elevation: 0,
            ),
          ),
          if (_selectedFileName != null && _parsedTransactions == null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadStatement,
                style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: _bg),
                child: Text('Process via Groq AI', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final tSpend = _parsedSummary?['totalSpend'] ?? '0';
    final topCat = _parsedSummary?['topCategory'] ?? 'N/A';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('Total Spend', '\u20B9$tSpend', _spenderAccent),
          _statCol('Top Category', topCat, _gold),
        ],
      ),
    );
  }

  Widget _statCol(String label, String val, Color c) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: _textSecondary)),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: c)),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _parsedTransactions!.length,
      itemBuilder: (ctx, i) {
        final tx = _parsedTransactions![i] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx['merchant'] ?? 'Unknown', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(tx['category'] ?? 'Other', style: GoogleFonts.poppins(color: _textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text('\u20B9\${tx["amount"]}'.replaceAll(r'\$', r'$'), style: GoogleFonts.poppins(color: _spenderAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}
