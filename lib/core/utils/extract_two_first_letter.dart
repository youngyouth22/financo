String extractTwoFirstLetter(String input) {
  if (input.isEmpty) return '';
  List<String> words = input.trim().split(' ');
  if (words.length == 1) {
    return words[0].substring(0, 1).toUpperCase();
  } else {
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }
}