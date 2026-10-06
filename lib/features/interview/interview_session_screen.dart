import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/interview.dart';
import '../../services/interview_scoring_service.dart';
import '../../services/sql_result_grader.dart';
import '../game/game_providers.dart';

class InterviewSessionScreen extends ConsumerStatefulWidget {
  const InterviewSessionScreen({
    super.key,
    required this.round,
    required this.timed,
  });

  final InterviewRoundDefinition round;
  final bool timed;

  @override
  ConsumerState<InterviewSessionScreen> createState() =>
      _InterviewSessionScreenState();
}

class _InterviewSessionScreenState
    extends ConsumerState<InterviewSessionScreen> {
  final _answerController = TextEditingController();
  Timer? _timer;
  int _questionIndex = 0;
  int _earnedPoints = 0;
  int _remainingSeconds = 0;
  String _choice = '';
  String? _feedback;
  bool _submitted = false;
  bool _finishing = false;
  int? _finalScore;

  InterviewQuestion get _question =>
      widget.round.questions[_questionIndex];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.round.durationSeconds;
    if (widget.timed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _finalScore != null) return;
        if (_remainingSeconds <= 1) {
          setState(() => _remainingSeconds = 0);
          _finish();
        } else {
          setState(() => _remainingSeconds--);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finalScore != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.round.title)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Icon(
                _finalScore! >= 70
                    ? Icons.verified_outlined
                    : Icons.refresh_outlined,
                size: 54,
              ),
              const SizedBox(height: 12),
              Text(
                'Interview score: $_finalScore/100',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _finalScore! >= 70
                    ? 'Interview-ready performance. Your best score is saved offline.'
                    : 'Use the feedback to improve weak criteria, then retry.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to interview rounds'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.round.title),
        actions: [
          if (widget.timed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(_formatTime(_remainingSeconds)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LinearProgressIndicator(
              value: (_questionIndex + 1) / widget.round.questions.length,
            ),
            const SizedBox(height: 12),
            Text(
              'Question ${_questionIndex + 1} of '
              '${widget.round.questions.length}',
            ),
            const SizedBox(height: 8),
            Text(
              _question.context,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            Text(
              _question.prompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_question.answerType == 'choice')
              for (final option in _question.options)
                Card(
                  child: ListTile(
                    leading: Icon(
                      _choice == option
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(option),
                    selected: _choice == option,
                    onTap: _submitted
                        ? null
                        : () => setState(() => _choice = option),
                  ),
                )
            else
              TextField(
                controller: _answerController,
                enabled: !_submitted,
                minLines: _question.answerType == 'sql_result' ? 6 : 5,
                maxLines: 12,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  labelText: _question.answerType == 'sql_result'
                      ? 'SQL query'
                      : 'Your interview answer',
                  hintText: _question.answerType == 'sql_result'
                      ? 'SELECT ...'
                      : 'Structure the answer around the decision and evidence...',
                ),
              ),
            const SizedBox(height: 12),
            if (!_submitted)
              FilledButton(
                onPressed: _submitCurrent,
                child: const Text('Submit answer'),
              )
            else
              FilledButton(
                onPressed: _questionIndex ==
                        widget.round.questions.length - 1
                    ? _finish
                    : _nextQuestion,
                child: Text(
                  _questionIndex == widget.round.questions.length - 1
                      ? 'Finish round'
                      : 'Next question',
                ),
              ),
            if (_feedback != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_feedback!),
                ),
              ),
              const SizedBox(height: 8),
              Text(_question.explanation),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitCurrent() async {
    InterviewQuestionScore score;

    if (_question.answerType == 'choice') {
      if (_choice.isEmpty) {
        setState(() => _feedback = 'Choose an answer first.');
        return;
      }
      score = InterviewScoringService.scoreChoice(_question, _choice);
    } else if (_question.answerType == 'sql_result') {
      final run =
          await ref.read(sqlRunnerProvider).runReadOnly(_answerController.text);
      if (!run.isSuccess) {
        setState(() => _feedback = run.error);
        return;
      }
      final grade = SqlResultGrader.grade(
        actualRows: run.rows,
        expectedRows: _question.expectedRows,
      );
      score = InterviewQuestionScore(
        score: grade.isCorrect ? 100 : 0,
        feedback: grade.feedback,
      );
    } else {
      if (_answerController.text.trim().isEmpty) {
        setState(() => _feedback = 'Write an answer first.');
        return;
      }
      score = InterviewScoringService.scoreRubric(
        _question,
        _answerController.text,
      );
    }

    setState(() {
      _earnedPoints += score.score;
      _feedback = score.feedback;
      _submitted = true;
    });
  }

  void _nextQuestion() {
    setState(() {
      _questionIndex++;
      _answerController.clear();
      _choice = '';
      _feedback = null;
      _submitted = false;
    });
  }

  Future<void> _finish() async {
    if (_finishing || _finalScore != null) return;
    _finishing = true;
    _timer?.cancel();

    final finalScore =
        (_earnedPoints / widget.round.questions.length).round();
    await ref.read(interviewResultRepositoryProvider).save(
          roundKey: widget.round.key,
          score: finalScore,
          timed: widget.timed,
        );

    final skillKey = switch (widget.round.key) {
      'sql' => 'sql',
      'statistics' => 'statistics',
      _ => 'business',
    };
    await ref
        .read(masteryRepositoryProvider)
        .recordAttempt(skillKey, finalScore);

    ref.invalidate(interviewResultsProvider);
    ref.invalidate(skillProfileProvider);
    ref.invalidate(promotionReviewProvider);

    if (!mounted) return;
    setState(() {
      _finalScore = finalScore;
      _finishing = false;
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}
