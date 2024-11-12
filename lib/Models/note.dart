class Note {
  final int id;
  final String title;
  final String content;
  final String priority;
  final int archived;
  

  Note(
      {required this.id,
      required this.title,
      required this.content,
      required this.priority,
      required this.archived,});
}