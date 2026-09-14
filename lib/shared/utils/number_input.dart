/// Parses an ungrouped decimal entered with a mobile number keyboard.
///
/// Decimal keyboards can emit a comma or Arabic decimal separator depending
/// on the device locale, even when the app uses a different display language.
/// Reject non-finite values and mixed separators instead of saving bad data.
double? parseDecimalInput(String input) {
  final normalized = input.trim().runes.map((rune) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      return String.fromCharCode(0x30 + rune - 0x0660);
    }
    if (rune >= 0x06f0 && rune <= 0x06f9) {
      return String.fromCharCode(0x30 + rune - 0x06f0);
    }
    if (rune == 0x2c || rune == 0x066b) return '.';
    return String.fromCharCode(rune);
  }).join();
  if (!RegExp(
    r'^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$',
  ).hasMatch(normalized)) {
    return null;
  }
  final value = double.tryParse(normalized);
  return value != null && value.isFinite ? value : null;
}
