import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models.dart';

/// Builds and shares a professional PDF monitoring report from real stored
/// application data (never invented numbers). English layout.
class ReportService {
  ReportService._();

  static Future<void> shareMonitoringReport({
    required String rangeLabel,
    required List<SensorReading> readings,
    required List<AlertRecord> alerts,
  }) async {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final generatedAt = DateTime.now();
    final containsDemo = readings.any((r) => r.source == ReadingSource.demo);

    final total = readings.length;
    final risks = readings
        .where((r) => r.riskScore != null)
        .map((r) => r.riskScore!)
        .toList();
    final avgRisk =
        risks.isEmpty ? null : risks.reduce((a, b) => a + b) / risks.length;
    final maxRisk =
        risks.isEmpty ? null : risks.reduce((a, b) => a > b ? a : b);
    final safeCount = readings.where((r) => r.riskLevel == 'SAFE').length;

    final distribution = <String, int>{
      'SAFE': 0,
      'MEDIUM': 0,
      'HIGH': 0,
      'CRITICAL': 0,
    };
    for (final r in readings) {
      final lvl = r.riskLevel;
      if (lvl != null && distribution.containsKey(lvl)) {
        distribution[lvl] = distribution[lvl]! + 1;
      }
    }

    pw.Widget statRow(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(color: PdfColors.grey700)),
              pw.Text(value,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );

    pw.Widget sectionTitle(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
          child: pw.Text(
            t.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
              letterSpacing: 1.2,
            ),
          ),
        );

    final recentReadings = readings.length > 15
        ? readings.sublist(readings.length - 15)
        : readings;
    final recentAlerts = alerts.length > 10 ? alerts.sublist(0, 10) : alerts;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(36)),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Text(
            'Smart Guardian Egypt - supplementary monitoring tool. Not a replacement for certified fire detection systems or emergency services.'
            '${containsDemo ? ' This report includes SIMULATED demo data.' : ''}'
            '  Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SMART GUARDIAN EGYPT',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Intelligence That Protects. Technology That Builds the Future.',
                    style: const pw.TextStyle(
                        fontSize: 8.5, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Monitoring report',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(rangeLabel,
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey700)),
                  pw.Text('Generated ${df.format(generatedAt)}',
                      style: const pw.TextStyle(
                          fontSize: 8.5, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.blue800, thickness: 1.2),
          if (containsDemo)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: PdfColors.amber, width: 0.8),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'DEMO DATA: this range contains simulated readings produced by Demo Mode. They are not real sensor measurements.',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.orange900),
              ),
            ),
          sectionTitle('Summary'),
          statRow('Total sensor readings', '$total'),
          statRow('Total alerts', '${alerts.length}'),
          statRow('Average risk score',
              avgRisk == null ? '--' : '${avgRisk.toStringAsFixed(1)}%'),
          statRow('Highest risk score',
              maxRisk == null ? '--' : '${maxRisk.toStringAsFixed(0)}%'),
          statRow(
              'Safe readings',
              total == 0
                  ? '--'
                  : '${(safeCount / total * 100).toStringAsFixed(0)}%'),
          sectionTitle('Risk distribution'),
          pw.TableHelper.fromTextArray(
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ['Level', 'Readings', 'Share'],
            data: [
              for (final e in distribution.entries)
                [
                  e.key,
                  '${e.value}',
                  total == 0
                      ? '--'
                      : '${(e.value / total * 100).toStringAsFixed(1)}%',
                ],
            ],
          ),
          sectionTitle('Recent readings (last ${recentReadings.length})'),
          recentReadings.isEmpty
              ? pw.Text('No readings in this range.',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
              : pw.TableHelper.fromTextArray(
                  headerStyle:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  headers: [
                    'Time',
                    'Temp °C',
                    'Hum %',
                    'Smoke',
                    'Gas',
                    'Flame',
                    'Risk',
                    'Level',
                    'Source'
                  ],
                  data: [
                    for (final r in recentReadings.reversed)
                      [
                        df.format(r.timestamp),
                        r.temperature?.toStringAsFixed(1) ?? '--',
                        r.humidity?.toStringAsFixed(0) ?? '--',
                        r.smoke?.toStringAsFixed(0) ?? '--',
                        r.gas?.toStringAsFixed(0) ?? '--',
                        r.flameDetected ? 'YES' : 'no',
                        r.riskScore?.toStringAsFixed(0) ?? '--',
                        r.riskLevel ?? '--',
                        r.source == ReadingSource.demo ? 'DEMO' : 'live',
                      ],
                  ],
                ),
          sectionTitle('Recent alerts (last ${recentAlerts.length})'),
          recentAlerts.isEmpty
              ? pw.Text('No alerts in this range.',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
              : pw.TableHelper.fromTextArray(
                  headerStyle:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  headers: ['Time', 'Severity', 'Type', 'Message'],
                  data: [
                    for (final a in recentAlerts)
                      [
                        df.format(a.timestamp),
                        a.severity,
                        a.type,
                        a.message.length > 90
                            ? '${a.message.substring(0, 90)}...'
                            : a.message,
                      ],
                  ],
                ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'smart_guardian_report_${DateFormat('yyyyMMdd_HHmm').format(generatedAt)}.pdf',
    );
  }
}
