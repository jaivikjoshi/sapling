import 'transaction_importer.dart';

class ReceiptTextParser {
  const ReceiptTextParser();

  ReceiptExtractionResult parse({
    required String attachmentId,
    required String text,
    DateTime? fallbackDate,
  }) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final amount = _bestTotal(lines) ?? _largestAmount(lines);
    return ReceiptExtractionResult(
      attachmentId: attachmentId,
      amount: amount,
      taxAmount: _taxAmount(lines),
      merchant: _merchant(lines),
      date: _date(lines) ?? fallbackDate,
      categorySuggestion: _category(lines),
      confidence: amount == null ? 0.35 : 0.78,
    );
  }

  double? _bestTotal(List<String> lines) {
    const totalLabels = ['grand total', 'total', 'amount paid', 'paid'];
    for (final label in totalLabels) {
      for (final line in lines.reversed) {
        if (!line.toLowerCase().contains(label)) continue;
        final amounts = _amounts(line);
        if (amounts.isNotEmpty) return amounts.last;
      }
    }
    return null;
  }

  double? _largestAmount(List<String> lines) {
    final amounts = lines.expand(_amounts).where((amount) => amount > 0);
    if (amounts.isEmpty) return null;
    return amounts.reduce((a, b) => a > b ? a : b);
  }

  double? _taxAmount(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!lower.contains('tax') &&
          !lower.contains('hst') &&
          !lower.contains('gst')) {
        continue;
      }
      final amounts = _amounts(line);
      if (amounts.isNotEmpty) return amounts.last;
    }
    return null;
  }

  String? _merchant(List<String> lines) {
    final ignored = RegExp(
      r'(receipt|invoice|transaction|total|subtotal|tax|visa|mastercard|debit|credit)',
      caseSensitive: false,
    );
    for (final line in lines.take(5)) {
      if (line.length < 2 ||
          ignored.hasMatch(line) ||
          _amounts(line).isNotEmpty) {
        continue;
      }
      return _titleCase(line);
    }
    return null;
  }

  DateTime? _date(List<String> lines) {
    for (final line in lines) {
      final slash = RegExp(
        r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b',
      ).firstMatch(line);
      if (slash != null) {
        final first = int.parse(slash.group(1)!);
        final second = int.parse(slash.group(2)!);
        final rawYear = int.parse(slash.group(3)!);
        final year = rawYear < 100 ? 2000 + rawYear : rawYear;
        final month = first > 12 ? second : first;
        final day = first > 12 ? first : second;
        return DateTime.tryParse(
          '${year.toString().padLeft(4, '0')}-'
          '${month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}',
        );
      }
      final iso = RegExp(r'\b(20\d{2})-(\d{1,2})-(\d{1,2})\b').firstMatch(line);
      if (iso != null) return DateTime.tryParse(iso.group(0)!);
    }
    return null;
  }

  String? _category(List<String> lines) {
    final text = lines.join(' ').toLowerCase();
    if (_hasAny(text, ['grocery', 'market', 'supermarket', 'whole foods'])) {
      return 'Groceries';
    }
    if (_hasAny(text, ['restaurant', 'cafe', 'coffee', 'burger', 'pizza'])) {
      return 'Food';
    }
    if (_hasAny(text, ['uber', 'lyft', 'transit', 'gas', 'fuel'])) {
      return 'Transportation';
    }
    if (_hasAny(text, ['pharmacy', 'clinic', 'medical'])) return 'Health';
    if (_hasAny(text, ['hydro', 'utility', 'internet', 'phone bill'])) {
      return 'Bills';
    }
    return 'Other';
  }

  Iterable<double> _amounts(String line) {
    return RegExp(r'(?:\$|CAD|USD)?\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{2}))')
        .allMatches(line)
        .map((match) => double.tryParse(match.group(1)!.replaceAll(',', '')))
        .whereType<double>();
  }

  bool _hasAny(String text, List<String> needles) => needles.any(text.contains);

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .map((word) {
          final lower = word.toLowerCase();
          if (lower.isEmpty) return lower;
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }
}
