class TarotMessage {
  TarotMessage({this.text, this.surfaceId, this.isUser = false, this.componentName, this.isError = false});

  final String? text;
  final String? surfaceId;
  final bool isUser;
  /// Primary A2UI component name (e.g. 'TarotCard', 'OracleMessage').
  final String? componentName;
  final bool isError;
}
