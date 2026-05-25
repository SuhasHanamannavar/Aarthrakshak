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
    text: 'Monthly savings kaise manage karte hain?',
    options: [
      _Option(text: 'SIP ya Mutual Funds mein invest karta hoon', archetype: Archetype.investor),
      _Option(text: 'FD ya RD mein safe rakhta hoon', archetype: Archetype.saver),
      _Option(text: 'Jo bachta hai, kuch naya kharid leta hoon', archetype: Archetype.spender),
      _Option(text: 'Sirf basic necessities par kharach karta hoon', archetype: Archetype.minimalist),
    ],
  ),
  _Question(
    text: 'Bonus milne par kya karte hain?',
    options: [
      _Option(text: 'Kisi ache fund mein invest kar deta hoon', archetype: Archetype.investor),
      _Option(text: 'Emergency fund mein daal deta hoon', archetype: Archetype.saver),
      _Option(text: 'Koi luxury item ya gadget kharid leta hoon', archetype: Archetype.spender),
      _Option(text: 'Kisi nayi jagah ghoomne ka plan banata hoon', archetype: Archetype.adventurer),
    ],
  ),
  _Question(
    text: 'EMI aur loans par aapka kya approach hai?',
    options: [
      _Option(text: 'Pehle save karke phir kharidna pasand karta hoon', archetype: Archetype.saver),
      _Option(text: 'Loan nahi leta, cash mein hi kharidta hoon', archetype: Archetype.minimalist),
      _Option(text: 'Jaroorat ho toh EMI le leta hoon', archetype: Archetype.spender),
      _Option(text: 'Loan lekar bhi invest karta hoon agar return zyada ho', archetype: Archetype.investor),
    ],
  ),
  _Question(
    text: 'UPI aur digital payments kaise use karte hain?',
    options: [
      _Option(text: 'Har cheez UPI se, tracking nahi karta', archetype: Archetype.spender),
      _Option(text: 'Budget ke andar UPI se pay karta hoon', archetype: Archetype.saver),
      _Option(text: 'Cash preferred hai, UPI sirf jaroorat par', archetype: Archetype.minimalist),
      _Option(text: 'Payments track karke investments plan karta hoon', archetype: Archetype.investor),
    ],
  ),
  _Question(
    text: 'Gold aur traditional savings par kya soch hai?',
    options: [
      _Option(text: 'Sona traditional investment ka hissa hai', archetype: Archetype.saver),
      _Option(text: 'Gold ETF ya SGB mein invest karta hoon', archetype: Archetype.investor),
      _Option(text: 'Sirf minimum gold, baaki liquid rakhta hoon', archetype: Archetype.minimalist),
      _Option(text: 'Gold se accha naye experiences par kharach karna', archetype: Archetype.adventurer),
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
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
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
          backgroundColor: const Color(0xFF141832),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Aap Hain: ${result.name[0].toUpperCase()}${result.name.substring(1)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
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
                'Chalein Dashboard',
                style: GoogleFonts.poppins(color: const Color(0xFFFFD700)),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _explanationPrompt(Archetype archetype) {
    final names = {
      Archetype.saver: 'Saver (Bachat karna pasand)',
      Archetype.spender: 'Spender (Kharach karne wala)',
      Archetype.investor: 'Investor (Nivesh karne wala)',
      Archetype.minimalist: 'Minimalist (Sirf zaroorat ki cheezein)',
      Archetype.adventurer: 'Adventurer (Naye experiences pasand)',
    };
    return 'User has been identified as a ${names[archetype]} financial personality. Explain this archetype in 3-4 lines in professional English — describe their financial habits, strengths, and how they can improve their savings. Use a friendly but professional tone.';
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
      backgroundColor: const Color(0xFF0A0E27),
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
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Apni Bachat Ka Rakshak',
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
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF0A0E27),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Shuru Karein'),
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
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF0A0E27),
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
                child: Text(index == 4 ? 'Dekhte Hain Result' : 'Aage Badhein \u2192'),
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
          'Prashna ${index + 1}/${_questions.length}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF8892B0),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF141832),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
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
          color: isSelected ? const Color(0xFFFFD700).withAlpha(30) : const Color(0xFF141832),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
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
                  color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 22),
          ],
        ),
      ),
    );
  }
}
