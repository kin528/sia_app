import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

const String adminUid = 'QVyiObd7HoXTyNQaoxBzRSW0HGK2';

class PlayModule3Page extends StatefulWidget {
  const PlayModule3Page({super.key});

  @override
  State<PlayModule3Page> createState() => _PlayModule3PageState();
}

class _PlayModule3PageState extends State<PlayModule3Page> {
  int? _mode; // null: not selected, 0: edit, 1: play
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  String? _error;
  List<int> _shuffledIndexes = [];
  int _current = 0;
  int? _selectedChoice;
  bool _showFeedback = false;
  final bool _lastCorrect = false;
  int _score = 0;
  bool _quizFinished = false;
  List<int> _userAnswers = [];

  // Shuffled choices and answers for each question
  List<List<String>> _shuffledChoices = [];
  List<int> _shuffledAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    // If not admin, go directly to play mode
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid != adminUid) {
      _mode = 1;
      _startQuiz();
    }
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Quiz')
          .doc('module3')
          .get();
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!['questions'] != null) {
        final List<dynamic> qList = doc.data()!['questions'];
        _questions = qList.map((q) {
          final map = Map<String, dynamic>.from(q);
          map['choices'] = List<String>.from(map['choices'] as List);
          return map;
        }).toList();
      } else {
        _questions = List.generate(
          10,
          (i) => {
            'question': 'Question ${i + 1}?',
            'choices': [
              'Choice A',
              'Choice B',
              'Choice C',
              'Choice D',
            ],
            'answer': 0,
          },
        );
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load quiz: $e';
        _loading = false;
      });
    }
  }

  Future<void> _saveQuestions() async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('Quiz').doc('module3').set({
        'questions': _questions,
      });
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Quiz saved!')));
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  void _startQuiz() {
    _shuffledIndexes = List.generate(_questions.length, (i) => i)..shuffle();
    _current = 0;
    _selectedChoice = null;
    _showFeedback = false;
    _score = 0;
    _quizFinished = false;
    _userAnswers = List.filled(_questions.length, -1);

    // Shuffle choices and correct answer for each question
    final random = Random();
    _shuffledChoices = [];
    _shuffledAnswers = [];
    for (var q in _questions) {
      final choices = List<String>.from(q['choices']);
      final correctIndex = q['answer'] as int;
      final indexed = List.generate(
          choices.length, (i) => {'text': choices[i], 'index': i});
      indexed.shuffle(random);
      final newChoices = indexed.map((c) => c['text'] as String).toList();
      final newAnswer = indexed.indexWhere((c) => c['index'] == correctIndex);
      _shuffledChoices.add(newChoices);
      _shuffledAnswers.add(newAnswer);
    }
    setState(() {});
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('Quiz')
          .doc('module3')
          .collection('scores')
          .add({
        'score': _score,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });
    } catch (e) {
      print('Error saving score to Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = FirebaseAuth.instance.currentUser?.uid == adminUid;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final maxWidth = isWide ? 500.0 : double.infinity;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }
    return Scaffold(
      appBar: (_mode == null)
          ? AppBar(
              title: const Text('Play Module 3'),
              backgroundColor: Colors.green.shade400,
              elevation: 1,
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isWide ? 28 : 18),
            ),
            margin: EdgeInsets.all(isWide ? 32 : 12),
            child: Padding(
              padding: EdgeInsets.all(isWide ? 32.0 : 16.0),
              child: SingleChildScrollView(
                child: _mode == null
                    ? _buildModeSelect(context, isAdmin)
                    : _mode == 0
                        ? _buildEdit(context)
                        : _buildPlay(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelect(BuildContext context, bool isAdmin) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Icon(Icons.sports_esports, size: 56, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          "Module 3 Quiz",
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        if (isAdmin)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 24),
                textStyle:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => setState(() => _mode = 0),
              label: const Text('Edit'),
            ),
          ),
        if (isAdmin) const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24),
              textStyle:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              _startQuiz();
              setState(() => _mode = 1);
            },
            label: const Text('Play'),
          ),
        ),
      ],
    );
  }

  Widget _buildEdit(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _mode = null),
                tooltip: "Back",
              ),
              const SizedBox(width: 8),
              const Text(
                "Edit Questions",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_questions.length, (i) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Q${i + 1}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextFormField(
                      initialValue: _questions[i]['question'],
                      decoration: const InputDecoration(labelText: 'Question'),
                      onChanged: (val) => _questions[i]['question'] = val,
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                        4,
                        (j) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: j,
                                    groupValue: _questions[i]['answer'],
                                    onChanged: (val) {
                                      setState(
                                          () => _questions[i]['answer'] = val);
                                    },
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _questions[i]['choices'][j],
                                      decoration: InputDecoration(
                                          labelText:
                                              'Choice ${String.fromCharCode(65 + j)}'),
                                      onChanged: (val) =>
                                          _questions[i]['choices'][j] = val,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Save"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await _saveQuestions();
                setState(() => _mode = null);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlay(BuildContext context) {
    if (_shuffledIndexes.isEmpty) _startQuiz();
    final idx = _shuffledIndexes[_current];
    final q = _questions[idx]['question'] as String;
    final choices = _shuffledChoices[idx];
    final answer = _shuffledAnswers[idx];
    final isLast = _current == _questions.length - 1;
    if (_userAnswers[idx] != -1 && _selectedChoice == null) {
      _selectedChoice = _userAnswers[idx];
    }
    final progress = (_current + 1) / _questions.length;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _mode = null),
                  tooltip: "Back",
                ),
                const SizedBox(width: 8),
                Text(
                  "Quiz",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Question ${_current + 1} of ${_questions.length}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(
                        4,
                        (j) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Material(
                                color: Colors.transparent,
                                child: RadioListTile<int>(
                                  value: j,
                                  groupValue: _selectedChoice,
                                  title: Text(
                                    choices[j],
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  activeColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  tileColor: _selectedChoice == j
                                      ? Colors.blue.withOpacity(0.08)
                                      : Colors.transparent,
                                  onChanged: _showFeedback
                                      ? null
                                      : (val) =>
                                          setState(() => _selectedChoice = val),
                                ),
                              ),
                            )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_quizFinished)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _current > 0 && !_showFeedback
                          ? () {
                              setState(() {
                                _current--;
                                final prevIdx = _shuffledIndexes[_current];
                                _selectedChoice = _userAnswers[prevIdx] != -1
                                    ? _userAnswers[prevIdx]
                                    : null;
                                _showFeedback = false;
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Previous",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedChoice != null
                          ? () async {
                              _userAnswers[idx] = _selectedChoice!;
                              bool correct = _selectedChoice == answer;
                              if (correct) _score++;
                              if (isLast) {
                                setState(() {
                                  _quizFinished = true;
                                });
                                await _saveScore();
                              } else {
                                setState(() {
                                  _current++;
                                  _selectedChoice = null;
                                });
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isLast ? "Finish" : "Next",
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            if (_quizFinished) _buildReview(context),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.shuffle),
              label: const Text("Shuffle & Restart"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                _startQuiz();
                setState(() {
                  _quizFinished = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.reviews, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 8),
                Text(
                  "Review",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Your score: $_score/${_questions.length}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ...List.generate(_questions.length, (i) {
              final q = _questions[i]['question'] as String;
              final choices = _shuffledChoices[i];
              final answer = _shuffledAnswers[i];
              final userAns = _userAnswers[i];
              final isCorrect = userAns == answer;
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                color: userAns == -1
                    ? Colors.grey[100]
                    : isCorrect
                        ? Colors.green[50]
                        : Colors.red[50],
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Q${i + 1}: $q",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your answer: ${userAns != -1 && userAns < choices.length ? choices[userAns] : "No answer"}",
                        style: TextStyle(
                          color: userAns == -1
                              ? Colors.grey
                              : isCorrect
                                  ? Colors.green
                                  : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (!isCorrect &&
                          userAns != -1 &&
                          answer < choices.length)
                        Text(
                          "Correct answer: ${choices[answer]}",
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 15),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
