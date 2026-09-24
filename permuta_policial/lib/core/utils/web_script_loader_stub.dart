/// Stub para plataformas que não carregam scripts OCR via DOM.
class WebScriptLoader {
  WebScriptLoader._();

  static Future<void> ensureOcrScriptsLoaded() async {}
}
