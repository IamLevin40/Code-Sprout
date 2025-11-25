/// Utility functions for number formatting and display
class NumberUtils {
  /// Format large numbers into shortened string with suffixes (K, M, B, T)
  /// 
  /// Examples:
  /// - 950 → "950"
  /// - 1,200 → "1.2K"
  /// - 1,500,000 → "1.5M"
  /// - -9,876,543,210 → "-9.88B"
  /// - 1,234,567,890,123 → "1.23T"
  static String formatNumberShort(num value) {
    final double absVal = value.abs().toDouble();
    if (absVal < 1000) return value.toString();

    final List<String> suffixes = ['K', 'M', 'B', 'T'];
    double v = absVal;
    int idx = -1;
    while (v >= 1000 && idx < suffixes.length - 1) {
      v = v / 1000.0;
      idx++;
    }

    if (idx < 0) return value.toString();

    // Decide decimals: K and M -> 1 decimal, B and T -> 2 decimals
    final int decimals = (idx <= 1) ? 1 : 2;

    final String formatted = v.toStringAsFixed(decimals);
    final String sign = value < 0 ? '-' : '';
    return '$sign$formatted${suffixes[idx]}';
  }
}
