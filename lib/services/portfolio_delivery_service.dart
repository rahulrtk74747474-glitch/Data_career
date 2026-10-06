import 'package:flutter/rendering.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class PortfolioOpenResult {
  const PortfolioOpenResult({
    required this.opened,
    required this.message,
  });

  final bool opened;
  final String message;
}

class PortfolioDeliveryService {
  const PortfolioDeliveryService();

  Future<PortfolioOpenResult> open(String path) async {
    final result = await OpenFile.open(path);
    return PortfolioOpenResult(
      opened: result.type == ResultType.done,
      message: result.message,
    );
  }

  Future<ShareResult> share(
    String path, {
    Rect? sharePositionOrigin,
    String title = 'DataQuest Analyst Portfolio',
    String text =
        'DataQuest analyst portfolio evidence report. Open in a browser to print or save as PDF.',
  }) {
    return SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: title,
        text: text,
        files: [XFile(path)],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
