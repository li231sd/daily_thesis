/// A single tappable interest option shown to the user.
/// Each option maps to exactly one backend `subject` key used by the Worker.
class InterestOption {
  final String label;
  final String subjectKey;

  const InterestOption(this.label, this.subjectKey);
}

class InterestMatcher {
  /// Backend subject keys, matching OPENALEX_TOPICS / ARXIV_TOPICS in the Worker.
  static const List<String> availableSubjects = [
    'computer-science',
    'medicine',
    'biology',
    'physics',
    'mathematics',
    'economics',
    'psychology',
    'chemistry',
    'space',
  ];

  static String displayName(String subjectKey) {
    switch (subjectKey) {
      case 'computer-science':
        return 'Computer Science';
      case 'medicine':
        return 'Medicine';
      case 'biology':
        return 'Biology';
      case 'physics':
        return 'Physics';
      case 'mathematics':
        return 'Mathematics';
      case 'economics':
        return 'Economics';
      case 'psychology':
        return 'Psychology';
      case 'chemistry':
        return 'Chemistry';
      case 'space':
        return 'Space';
      default:
        return subjectKey;
    }
  }

  /// Curated, tappable interest options grouped by subject. Several specific
  /// options can map to the same backend subject (e.g. "Quantum Mechanics"
  /// and "Astrophysics" both map to 'physics'), giving users a richer,
  /// no-typing-required picker while keeping the backend mapping exact.
  static const Map<String, List<InterestOption>> groupedOptions = {
    'Computer Science': [
      InterestOption('Artificial Intelligence', 'computer-science'),
      InterestOption('Machine Learning', 'computer-science'),
      InterestOption('Robotics', 'computer-science'),
      InterestOption('Cybersecurity', 'computer-science'),
      InterestOption('Software Engineering', 'computer-science'),
      InterestOption('Data Science', 'computer-science'),
      InterestOption('Computer Vision', 'computer-science'),
      InterestOption('Algorithms & Theory', 'computer-science'),
    ],
    'Medicine': [
      InterestOption('Clinical Research', 'medicine'),
      InterestOption('Public Health', 'medicine'),
      InterestOption('Pharmacology', 'medicine'),
      InterestOption('Surgery', 'medicine'),
      InterestOption('Epidemiology', 'medicine'),
      InterestOption('Genetics & Disease', 'medicine'),
    ],
    'Biology': [
      InterestOption('Genetics', 'biology'),
      InterestOption('Evolution', 'biology'),
      InterestOption('Ecology', 'biology'),
      InterestOption('Microbiology', 'biology'),
      InterestOption('Marine Biology', 'biology'),
      InterestOption('Biotechnology', 'biology'),
      InterestOption('Neuroscience', 'biology'),
    ],
    'Physics': [
      InterestOption('Quantum Mechanics', 'physics'),
      InterestOption('Particle Physics', 'physics'),
      InterestOption('Condensed Matter', 'physics'),
      InterestOption('Thermodynamics', 'physics'),
      InterestOption('High Energy Physics', 'physics'),
    ],
    'Mathematics': [
      InterestOption('Number Theory', 'mathematics'),
      InterestOption('Combinatorics', 'mathematics'),
      InterestOption('Probability', 'mathematics'),
      InterestOption('Pure Mathematics', 'mathematics'),
      InterestOption('Applied Mathematics', 'mathematics'),
    ],
    'Economics': [
      InterestOption('Macroeconomics', 'economics'),
      InterestOption('Microeconomics', 'economics'),
      InterestOption('Behavioral Economics', 'economics'),
      InterestOption('Econometrics', 'economics'),
      InterestOption('Markets & Finance', 'economics'),
    ],
    'Psychology': [
      InterestOption('Cognitive Psychology', 'psychology'),
      InterestOption('Mental Health', 'psychology'),
      InterestOption('Behavioral Science', 'psychology'),
      InterestOption('Developmental Psychology', 'psychology'),
      InterestOption('Social Psychology', 'psychology'),
    ],
    'Chemistry': [
      InterestOption('Organic Chemistry', 'chemistry'),
      InterestOption('Biochemistry', 'chemistry'),
      InterestOption('Materials Science', 'chemistry'),
      InterestOption('Physical Chemistry', 'chemistry'),
    ],
    'Space': [
      InterestOption('Astrophysics', 'space'),
      InterestOption('Cosmology', 'space'),
      InterestOption('Exoplanets', 'space'),
      InterestOption('Astronomy', 'space'),
      InterestOption('Space Exploration', 'space'),
    ],
  };

  /// Given a user's selected option labels, returns the deduplicated set of
  /// backend subject keys those selections map to.
  static List<String> subjectsForSelections(List<String> selectedLabels) {
    final selectedSet = selectedLabels.toSet();
    final subjects = <String>{};

    for (final group in groupedOptions.values) {
      for (final option in group) {
        if (selectedSet.contains(option.label)) {
          subjects.add(option.subjectKey);
        }
      }
    }

    return subjects.toList();
  }

  /// Deterministically picks one subject per day from the user's matched
  /// subjects, so the app rotates through their interests instead of always
  /// hitting the same one. Falls back to 'all' if the user has no subjects.
  static String subjectForToday(List<String> matchedSubjects) {
    if (matchedSubjects.isEmpty) return 'all';
    if (matchedSubjects.length == 1) return matchedSubjects.first;

    final today = DateTime.now();
    final dayIndex = today.year * 365 + today.month * 30 + today.day;
    final sorted = [...matchedSubjects]..sort();

    return sorted[dayIndex % sorted.length];
  }
}
