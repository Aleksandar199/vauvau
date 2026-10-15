/// Max characters (runes) of a `lastMessage` inbox preview.
///
/// `firestore.rules` rejects previews longer than 1000, so long messages are
/// clipped here instead of failing the preview write after the message is sent.
const int kLastMessagePreviewMax = 200;

String clipLastMessagePreview(String raw) {
  final text = raw.trim();
  final runes = text.runes;
  if (runes.length <= kLastMessagePreviewMax) {
    return text;
  }
  return '${String.fromCharCodes(runes.take(kLastMessagePreviewMax - 1))}…';
}
