class BlockReportItem {
  final int blockId;
  final String status;
  final int completionPercent;

  BlockReportItem({
    required this.blockId,
    required this.status,
    required this.completionPercent,
  });

  Map<String, dynamic> toJson() {
    return {
      'block_id': blockId,
      'status': status,
      'completion_percent': completionPercent,
    };
  }

  factory BlockReportItem.fromJson(Map<String, dynamic> json) {
    return BlockReportItem(
      blockId: json['block_id'],
      status: json['status'],
      completionPercent: json['completion_percent'],
    );
  }
}

class ReportSubmitRequest {
  final int userId;
  final String date;
  final List<BlockReportItem> blocks;
  final String? notes;

  ReportSubmitRequest({
    required this.userId,
    required this.date,
    required this.blocks,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'notes': notes,
    };
  }
}

class ReportSubmitResponse {
  final int reportId;
  final int blocksCompleted;
  final int blocksPartial;
  final int blocksMissed;
  final int rescheduledCount;

  ReportSubmitResponse({
    required this.reportId,
    required this.blocksCompleted,
    required this.blocksPartial,
    required this.blocksMissed,
    required this.rescheduledCount,
  });

  factory ReportSubmitResponse.fromJson(Map<String, dynamic> json) {
    return ReportSubmitResponse(
      reportId: json['report_id'],
      blocksCompleted: json['blocks_completed'],
      blocksPartial: json['blocks_partial'],
      blocksMissed: json['blocks_missed'],
      rescheduledCount: json['rescheduled_count'],
    );
  }
}
