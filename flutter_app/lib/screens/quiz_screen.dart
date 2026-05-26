import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/archetype.dart';
import '../services/groq_service.dart';
import '../state/app_state.dart';

class _Question {
  final String text;
  final List<_Option> options;

  const _Question({required this.text, required this.options});
}

class _Option {
  final String text;
  final Archetype archetype;

  const _Option({required this.text, required this.archetype});
}

const List<_Question> _questions = [
  _Question(
    text: 'How do you manage your monthly savings?',
    options: [
      _Option(text: 'I invest in SIPs or Mutual Funds', archetype: Archetype.investor),
      _Option(text: 'I keep it safe in FDs or RDs', archetype: Archetype.saver),
      _Option(text: 'I spend whatever is left on new purchases', archetype: Archetype.spender),
      _Option(text: 'I only spend on basic necessities', archetype: Archetype.minimalist),
    ],
  ),
  _Question(
    text: 'What do you do when you receive a commercial bonus?',
    options: [
      _Option(text: 'I invest it in a high-performing fund', archetype: Archetype.investor),
      _Option(text: 'I allocate it strictly to my emergency safety net', archetype: Archetype.saver),
      _Option(text: 'I purchase a luxury item or gadget', archetype: Archetype.spender),
      _Option(text: 'I plan an adventurous trip to a new destination', archetype: Archetype.adventurer),
    ],
  ),
  _Question(
    text: 'What is your strategic approach to EMIs and loans?',
    options: [
      _Option(text: 'I prefer to save first and buy capital later', archetype: Archetype.saver),
      _Option(text: 'I avoid debt entirely and rely strictly on cash', archetype: Archetype.minimalist),
      _Option(text: 'I finance purchases through EMIs whenever needed', archetype: Archetype.spender),
      _Option(text: 'I utilize leverage to invest if returns exceed interest', archetype: Archetype.investor),
    ],
  ),
  _Question(
    text: 'How do you utilize digital payment infrastructure (UPI)?',
    options: [
      _Option(text: 'I transact digitally for convenience without tracking', archetype: Archetype.spender),
      _Option(text: 'I transact strictly within my planned financial budget', archetype: Archetype.saver),
      _Option(text: 'I prefer cash and use digital gateways minimally', archetype: Archetype.minimalist),
      _Option(text: 'I track all digital ledger payments to plan investments', archetype: Archetype.investor),
    ],
  ),
  _Question(
    text: 'What are your thoughts on Gold and physical liquid assets?',
    options: [
      _Option(text: 'Physical gold is a fundamental part of investment', archetype: Archetype.saver),
      _Option(text: 'I prefer Sovereign Gold Bonds (SGB) and Gold ETFs', archetype: Archetype.investor),
      _Option(text: 'I maintain minimal physical wealth and hold liquid cash', archetype: Archetype.minimalist),
      _Option(text: 'I prefer investing in new experiences rather than metals', archetype: Archetype.adventurer),
    ],
  ),
];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<int, int> _selectedOptions = {};
  final Map<Archetype, int> _scores = {
    for (final a in Archetype.values) a: 0,
  };

  void _onOptionTap(int questionIndex, int optionIndex) {
    final prevOption = _selectedOptions[questionIndex];
    if (prevOption == optionIndex) return;

    final question = _questions[questionIndex];
    if (prevOption != null) {
      _scores[question.options[prevOption].archetype] =
          (_scores[question.options[prevOption].archetype] ?? 1) - 1;
    }
    _scores[question.options[optionIndex].archetype] =
        (_scores[question.options[optionIndex].archetype] ?? 0) + 1;
    _selectedOptions[questionIndex] = optionIndex;
    setState(() {});
  }

  void _onNextPressed() {
    if (_currentPage == 5) {
      final result = archetypeFromScores(_scores);
      context.read<AppState>().setArchetype(result);
      _showResultWithExplanation(result);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _showResultWithExplanation(Archetype result) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      ),
    );

    final explanation = await GroqService.complete(
      prompt: _explanationPrompt(result),
      model: 'mixtral-8x7b-32768',
      temperature: 0.7,
      maxTokens: 512,
    );

    if (mounted) Navigator.pop(context);

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Your Archetype: ${result.name[0].toUpperCase()}${result.name.substring(1)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD4AF37),
            ),
          ),
          content: Text(
            explanation ?? _fallbackExplanation(result),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
              child: Text(
                'Go to Dashboard',
                style: GoogleFonts.poppins(color: const Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _explanationPrompt(Archetype archetype) {
    final names = {
      Archetype.saver: 'Saver (Highly risk averse, prefers secure cash reserves)',
      Archetype.spender: 'Spender (High consumption, liquidity prioritizing)',
      Archetype.investor: 'Investor (Yield maximizing, portfolio optimizing)',
      Archetype.minimalist: 'Minimalist (Capital preserving, essentialist)',
      Archetype.adventurer: 'Adventurer (Experience prioritizing consumer)',
    };
    return 'User has been evaluated as a ${names[archetype]} financial personality. Detail this archetype in 3-4 professional lines. Describe strategic spending habits, financial strengths, and recommend advanced paths for optimal growth. Adopt a highly polished financial advisory tone.';
  }

  String _fallbackExplanation(Archetype archetype) {
    switch (archetype) {
      case Archetype.saver:
        return 'You are a Saver! Your habit of saving gives you financial security. Start small SIPs or mutual funds to help your savings grow further.';
      case Archetype.spender:
        return 'You are a Spender! You know how to enjoy life. Try tracking your expenses and follow the 50-30-20 rule: 50% needs, 30% wants, 20% savings.';
      case Archetype.investor:
        return 'You are an Investor! You understand how to grow your money. Diversify your portfolio and focus on long-term financial goals.';
      case Archetype.minimalist:
        return 'You are a Minimalist! Spending only on necessities is a great habit. Consider investing a portion of your savings for future growth.';
      case Archetype.adventurer:
        return 'You are an Adventurer! You love spending on experiences. Alongside travel and leisure, build an emergency fund for financial security.';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _currentPage = page),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildOpeningCard(),
          ...List.generate(_questions.length, (i) => _buildQuestionPage(i)),
        ],
      ),
    );
  }

  Widget _buildOpeningCard() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aarthrakshak',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Financial Guardian',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF09090B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Start Assessment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = _questions[index];
    final selected = _selectedOptions[index];
    final progress = (index + 1) / _questions.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(index, progress),
            const SizedBox(height: 32),
            Text(
              question.text,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: question.options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _buildOptionCard(
                  option: question.options[i],
                  isSelected: selected == i,
                  onTap: () => _onOptionTap(index, i),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: selected != null ? _onNextPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF09090B),
                  disabledBackgroundColor: Colors.grey.shade800,
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(index == 4 ? 'View Results' : 'Next Question \u2192'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int index, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question ${index + 1}/${_questions.length}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFFA1A1AA),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required _Option option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withAlpha(30) : const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.text,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 22),
          ],
        ),
      ),
    );
  }
}
