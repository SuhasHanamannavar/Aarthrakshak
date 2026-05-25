enum Archetype { saver, spender, investor, minimalist, adventurer }

Archetype archetypeFromScores(Map<Archetype, int> scores) {
  Archetype result = Archetype.saver;
  int maxScore = -1;
  for (final entry in scores.entries) {
    if (entry.value > maxScore) {
      maxScore = entry.value;
      result = entry.key;
    }
  }
  return result;
}
