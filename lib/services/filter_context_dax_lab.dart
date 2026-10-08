/// Deterministic in-app DAX filter-context teaching engine.
/// Supports a tiny subset of DAX, not Microsoft Power BI or DAX runtime.
/// Validates real relationship propagation and CALCULATE filter override.
class FilterContextDaxLab {
  const FilterContextDaxLab._();

  static const customers = <Map<String, Object>>[
    {'customer_id': 'C01', 'region': 'North'},
    {'customer_id': 'C02', 'region': 'South'},
    {'customer_id': 'C03', 'region': 'North'},
  ];
  static const sales = <Map<String, Object>>[
    {'order_id': 'A01', 'customer_id': 'C01', 'amount': 1000},
    {'order_id': 'A02', 'customer_id': 'C01', 'amount': 500},
    {'order_id': 'A03', 'customer_id': 'C02', 'amount': 1200},
    {'order_id': 'A04', 'customer_id': 'C03', 'amount': 800},
    {'order_id': 'A05', 'customer_id': 'C02', 'amount': 700},
  ];

  static int evaluate(String source, {String? slicerRegion}) {
    var code = source.trim();
    final assignment = RegExp(r'^[A-Za-z_][A-Za-z_ 0-9]*\s*=\s*');
    code = code.replaceFirst(assignment, '').trim();
    final normalized = code.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final sum = RegExp(r'^sum\(sales\[amount\]\)$');
    final all = RegExp(
      r'^calculate\(sum\(sales\[amount\]\),all\(customers\)\)$',
    );
    final filter = RegExp(
      r'''^calculate\(sum\(sales\[amount\]\),customers\[region\]=["'](north|south)["']\)$''',
    );
    String? region = slicerRegion;
    if (all.hasMatch(normalized)) {
      region = null; // ALL removes the Customer dimension slicer.
    } else if (filter.hasMatch(normalized)) {
      region = filter.firstMatch(normalized)!.group(1)!;
    } else if (!sum.hasMatch(normalized)) {
      throw const FormatException(
        'Supported: SUM(Sales[amount]), '
        'CALCULATE(SUM(Sales[amount]), Customers[region]="North"), '
        'or CALCULATE(SUM(Sales[amount]), ALL(Customers)).',
      );
    }
    final filteredIds = <String>{
      for (final customer in customers)
        if (region == null ||
            (customer['region'] as String).toLowerCase() ==
                region.toLowerCase())
          customer['customer_id'] as String,
    };
    return sales.where(
      (item) => filteredIds.contains(item['customer_id']),
    ).fold<int>(0, (sum, row) => sum + (row['amount'] as int));
  }

  static bool passesAllRegionIndependentTask(String source) {
    try {
      return evaluate(source, slicerRegion: 'North') == 4200 &&
          evaluate(source, slicerRegion: 'South') == 4200 &&
          evaluate(source) == 4200;
    } on FormatException {
      return false;
    }
  }
}
