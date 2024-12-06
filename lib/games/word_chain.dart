import 'package:brain_teasers/components/header_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class WordChainGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const WordChainGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  });

  @override
  State<WordChainGame> createState() => _WordChainGameState();
}

class _WordChainGameState extends State<WordChainGame> {
  late String startWord;
  late String targetWord;
  late List<String> wordChain;
  late TextEditingController _controller;
  String? errorMessage;
  int score = 0;
  int moves = 0;
  int maxMoves = 10;
  bool isComplete = false;

  @override
  void initState() {
    super.initState();
    startWord = widget.gameData['start'];
    targetWord = widget.gameData['end'];
    wordChain = [startWord];
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitWord(String newWord) {
    if (newWord.isEmpty) {
      setState(() => errorMessage = 'Please enter a word');
      return;
    }

    if (newWord.length != startWord.length) {
      setState(
          () => errorMessage = 'Word must be ${startWord.length} letters long');
      return;
    }

    if (!_isOneLetterDifferent(wordChain.last, newWord)) {
      setState(() => errorMessage = 'You can only change one letter at a time');
      return;
    }

    setState(() {
      errorMessage = null;
      wordChain.add(newWord);
      _controller.clear();
      moves++;

      // Calculate score based on moves and word length
      final moveScore = 100 - (moves * 10);
      score += moveScore > 0 ? moveScore : 10;
      widget.onScoreUpdate(score);

      if (newWord == targetWord) {
        isComplete = true;
        widget.onComplete();
      } else if (moves >= maxMoves) {
        errorMessage = 'Out of moves! Game Over';
      }
    });
  }

  bool _isOneLetterDifferent(String word1, String word2) {
    if (word1.length != word2.length) return false;
    int differences = 0;

    for (int i = 0; i < word1.length; i++) {
      if (word1[i] != word2[i]) differences++;
      if (differences > 1) return false;
    }

    return differences == 1;
  }

  void _undoLastMove() {
    if (wordChain.length > 1) {
      setState(() {
        wordChain.removeLast();
        moves--;
        errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildWordChain(),
          ),
          if (!isComplete) _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return HeaderContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Word Chain',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Change one letter at a time',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              _buildScoreDisplay(),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.stars_rounded,
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 8),
          Text(
            score.toString(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Moves: $moves/$maxMoves',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
            Text(
              '${((maxMoves - moves) / maxMoves * 100).toInt()}% remaining',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: 1 - (moves / maxMoves),
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              moves < maxMoves * 0.7
                  ? AppTheme.correctAnswerColor
                  : AppTheme.wrongAnswerColor,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildWordChain() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wordChain.length,
      itemBuilder: (context, index) {
        final word = wordChain[index];
        final previousWord = index > 0 ? wordChain[index - 1] : null;

        return _WordChainItem(
          word: word,
          previousWord: previousWord,
          isStart: index == 0,
          isEnd: word == targetWord,
          targetWord: targetWord,
        )
            .animate()
            .slideX(
              begin: 0.3,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            )
            .fadeIn(
              duration: const Duration(milliseconds: 300),
            );
      },
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: -10,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.wrongAnswerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage!,
                style: GoogleFonts.poppins(
                  color: AppTheme.wrongAnswerColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !isComplete && moves < maxMoves,
                  decoration: InputDecoration(
                    hintText: 'Enter next word...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: _submitWord,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: wordChain.length > 1 ? _undoLastMove : null,
                icon: const Icon(Icons.undo),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Target word: $targetWord',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WordChainItem extends StatelessWidget {
  final String word;
  final String? previousWord;
  final bool isStart;
  final bool isEnd;
  final String targetWord;

  const _WordChainItem({
    required this.word,
    required this.previousWord,
    required this.isStart,
    required this.isEnd,
    required this.targetWord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isStart
                  ? AppTheme.primaryColor
                  : isEnd
                      ? AppTheme.correctAnswerColor
                      : AppTheme.secondaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (isStart
                    ? 'S'
                    : isEnd
                        ? 'E'
                        : '•'),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWordComparison(word, previousWord),
                      if (!isEnd && !isStart)
                        _buildMatchIndicator(word, targetWord),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordComparison(String current, String? previous) {
    if (previous == null) {
      return Text(
        current,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      );
    }

    return Row(
      children: List.generate(current.length, (index) {
        final letter = current[index];
        final isChanged = previous[index] != letter;

        return Text(
          letter,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isChanged ? AppTheme.accentColor : AppTheme.primaryColor,
          ),
        );
      }),
    );
  }

  Widget _buildMatchIndicator(String current, String target) {
    int matches = 0;
    for (int i = 0; i < current.length; i++) {
      if (current[i] == target[i]) matches++;
    }

    return Row(
      children: [
        Text(
          '$matches/${target.length} matches',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.primaryColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
