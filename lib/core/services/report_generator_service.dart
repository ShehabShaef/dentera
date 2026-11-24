import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database/database_seeder.dart';
import '../../domain/entities/entities.dart';
import '../logging/app_logger.dart';

/// Data payload required to render an academic supervisory quota report.
class QuotaReportData {
  const QuotaReportData({
    required this.doctorName,
    required this.university,
    required this.academicYear,
    required this.generatedDate,
    required this.clinics,
    required this.requirements,
    required this.cases,
    required this.patients,
    this.filterClinicId,
    this.startDate,
    this.endDate,
    this.isDemoReport = false,
    this.localeCode = 'en',
  });

  final String doctorName;
  final String university;
  final String academicYear;
  final DateTime generatedDate;
  final List<Clinic> clinics;
  final List<Requirement> requirements;
  final List<CaseRecord> cases;
  final List<Patient> patients;
  final String? filterClinicId;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Marks this payload as a showcase Demo Report (used in Guest Mode), adding clear
  /// watermark banners across generated PDF and CSV files.
  final bool isDemoReport;

  /// Active UI locale code (`'en'` or `'ar'`) used to localize demo watermarks.
  final String localeCode;

  /// Human-readable date range label.
  String get dateRangeLabel {
    final df = DateFormat('yyyy-MM-dd');
    if (startDate != null && endDate != null) {
      return '${df.format(startDate!)} to ${df.format(endDate!)}';
    } else if (startDate != null) {
      return 'From ${df.format(startDate!)}';
    } else if (endDate != null) {
      return 'Until ${df.format(endDate!)}';
    }
    return 'All Time';
  }

  /// Returns filtered clinics based on [filterClinicId].
  List<Clinic> get visibleClinics {
    if (filterClinicId != null && filterClinicId!.isNotEmpty) {
      return clinics.where((c) => c.id == filterClinicId).toList();
    }
    return clinics;
  }

  /// Returns visible requirements matching the visible clinics.
  List<Requirement> get visibleRequirements {
    final clinicIds = visibleClinics.map((c) => c.id).toSet();
    return requirements.where((r) => clinicIds.contains(r.clinicId)).toList();
  }

  /// Returns visible cases associated with the visible requirements within date range.
  List<CaseRecord> get visibleCases {
    final reqIds = visibleRequirements.map((r) => r.id).toSet();
    return cases.where((c) {
      if (!reqIds.contains(c.requirementId)) return false;
      final caseDate = c.dateCompleted ?? c.dateStarted;
      if (startDate != null && caseDate.isBefore(startDate!)) return false;
      if (endDate != null) {
        final endOfDay = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59, 999);
        if (caseDate.isAfter(endOfDay)) return false;
      }
      return true;
    }).toList();
  }
}

/// Service generating supervisory PDF documents, CSV grading exports, and native sharing actions.
class ReportGeneratorService {
  const ReportGeneratorService();

  static pw.Font? _cachedBaseFont;
  static pw.Font? _cachedBoldFont;

  /// Loads and caches bundled Unicode Arabic TrueType fonts (Amiri-Regular and Amiri-Bold).
  /// Falls back gracefully to standard Helvetica if assets cannot be resolved.
  static Future<(pw.Font base, pw.Font bold)> loadArabicFonts() async {
    if (_cachedBaseFont != null && _cachedBoldFont != null) {
      return (_cachedBaseFont!, _cachedBoldFont!);
    }

    try {
      final baseData = await _loadFontByteData('assets/fonts/Amiri-Regular.ttf');
      final boldData = await _loadFontByteData('assets/fonts/Amiri-Bold.ttf');
      _cachedBaseFont = pw.Font.ttf(baseData);
      _cachedBoldFont = pw.Font.ttf(boldData);
      return (_cachedBaseFont!, _cachedBoldFont!);
    } catch (e) {
      AppLogger.warning('Failed to load embedded Arabic fonts; falling back to default PDF fonts: $e');
      return (pw.Font.helvetica(), pw.Font.helveticaBold());
    }
  }

  static Future<ByteData> _loadFontByteData(String path) async {
    try {
      return await rootBundle.load(path);
    } catch (_) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return ByteData.view(bytes.buffer);
      }
      rethrow;
    }
  }

  /// Determines whether [text] contains Arabic Unicode characters requiring
  /// RTL text directionality and Arabic glyph shaping.
  static bool hasArabicCharacters(String? text) {
    if (text == null || text.isEmpty) return false;
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text);
  }

  /// Builds a rich showcase [QuotaReportData] populated strictly from the Guest demo dataset
  /// with [isDemoReport] enforced to `true`.
  static QuotaReportData buildGuestDemoReportData({
    String localeCode = 'en',
    String? filterClinicId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? generatedDate,
  }) {
    final isAr = localeCode.toLowerCase().startsWith('ar');
    final now = generatedDate ?? DateTime.now();
    final demo = DatabaseSeeder.buildGuestDemoDataset(referenceNow: now);
    return QuotaReportData(
      doctorName: isAr ? 'د. ضيف' : 'Dr. Guest',
      university: 'Guest Dental University',
      academicYear: '5th Year',
      generatedDate: now,
      clinics: demo.clinics,
      requirements: demo.requirements,
      cases: demo.caseRecords,
      patients: demo.patients,
      filterClinicId: filterClinicId,
      startDate: startDate,
      endDate: endDate,
      isDemoReport: true,
      localeCode: localeCode,
    );
  }

  /// Generates a standardized academic PDF report containing clinician identity,
  /// department quota progress bars, evaluated cases, and supervisory sign-off blocks.
  ///
  /// When [QuotaReportData.isDemoReport] is `true`, inserts a prominent showcase banner
  /// across the document header and top body stating `"DEMO REPORT — FOR SHOWCASE ONLY (DEMO DATA)"`
  /// (plus its Arabic equivalent when `localeCode == 'ar'`) and `"DEMO REPORT — SAMPLE DATA ONLY"`.
  Future<Uint8List> generatePdfReport(QuotaReportData data) async {
    AppLogger.info(
      'Generating PDF ${data.isDemoReport ? "DEMO showcase" : "live"} supervisory quota report for ${data.doctorName}',
    );
    final doc = pw.Document();

    final (baseFont, boldFont) = await loadArabicFonts();
    final pdfTheme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      fontFallback: [baseFont],
    );

    final dateFormat = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormat.format(data.generatedDate);

    final patientMap = <String, Patient>{
      for (final p in data.patients) p.id: p,
    };
    final requirementMap = <String, Requirement>{
      for (final r in data.requirements) r.id: r,
    };
    final clinicMap = <String, Clinic>{
      for (final c in data.clinics) c.id: c,
    };

    final visibleClinics = data.visibleClinics;
    final visibleCases = data.visibleCases;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pdfTheme,
        header: (pw.Context context) => _buildPdfHeader(data, formattedDate),
        footer: (pw.Context context) => _buildPdfFooter(context, data),
        build: (pw.Context context) => <pw.Widget>[
          pw.SizedBox(height: 12),

          if (data.isDemoReport) ...[
            _buildDemoWatermarkBanner(data),
            pw.SizedBox(height: 14),
          ],

          // 1. Clinician Profile Metadata Box
          _buildMetadataBox(data, formattedDate),
          pw.SizedBox(height: 20),

          // 2. Department Quota Summary Table & Progress Bars
          _buildDepartmentQuotasSection(visibleClinics, data.requirements),
          pw.SizedBox(height: 20),

          // 3. Evaluated Cases Table
          _buildEvaluatedCasesSection(visibleCases, patientMap, requirementMap, clinicMap, dateFormat),
          pw.SizedBox(height: 32),

          // 4. Academic & Supervisory Sign-off Section
          _buildSupervisorySignOff(),
        ],
      ),
    );

    return await doc.save();
  }

  pw.Widget _buildDemoWatermarkBanner(QuotaReportData data) {
    final isAr = data.localeCode.toLowerCase().startsWith('ar');
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber800, width: 1.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            isAr
                ? 'تقرير تجريبي — للعرض فقط (بيانات تجريبية)'
                : 'DEMO REPORT — FOR SHOWCASE ONLY (DEMO DATA)',
            textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber900,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'DEMO REPORT — SAMPLE DATA ONLY • Not valid for official clinical submission',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfHeader(QuotaReportData data, String dateStr) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal700, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                'DENTERA CLINICAL SUPERVISORY REPORT',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                data.isDemoReport
                    ? 'DEMO REPORT — SAMPLE DATA ONLY'
                    : 'Official Academic Quota & Case Record Log',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: data.isDemoReport ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: data.isDemoReport ? PdfColors.amber900 : PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              if (data.isDemoReport)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const pw.EdgeInsets.only(bottom: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber100,
                    border: pw.Border.all(color: PdfColors.amber800, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    'DEMO',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber900,
                    ),
                  ),
                ),
              pw.Text(
                dateStr,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDoctorName(String raw) {
    final clean = raw.replaceAll(RegExp(r'^(dr\.|dr|doctor|د\.|د/|د)\s*', caseSensitive: false), '').trim();
    if (clean.isEmpty) return 'Dr. Doctor';
    final isArabic = hasArabicCharacters(clean);
    return isArabic ? 'د. $clean' : 'Dr. $clean';
  }

  pw.Widget _buildPdfFooter(pw.Context context, QuotaReportData data) {
    final formattedDoctor = _formatDoctorName(data.doctorName);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            formattedDoctor,
            textDirection: hasArabicCharacters(formattedDoctor) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount} • Dentera Academic Compliance',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetadataBox(QuotaReportData data, String dateStr) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                _metadataRow('Clinician Name:', _formatDoctorName(data.doctorName)),
                pw.SizedBox(height: 4),
                _metadataRow('Institution:', data.university),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                _metadataRow('Academic Year:', data.academicYear),
                pw.SizedBox(height: 4),
                _metadataRow('Date Range:', data.dateRangeLabel),
                pw.SizedBox(height: 4),
                _metadataRow('Report Date:', dateStr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _metadataRow(String label, String value) {
    final isRtl = hasArabicCharacters(value);
    return pw.Row(
      children: <pw.Widget>[
        pw.Text(
          '$label ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey800),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDepartmentQuotasSection(List<Clinic> clinics, List<Requirement> allReqs) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.teal50),
        children: <pw.Widget>[
          _tableHeader('Department'),
          _tableHeader('Target', align: pw.TextAlign.center),
          _tableHeader('Completed', align: pw.TextAlign.center),
          _tableHeader('Remaining', align: pw.TextAlign.center),
          _tableHeader('Progress %', align: pw.TextAlign.right),
        ],
      ),
    ];

    int grandTarget = 0;
    int grandCompleted = 0;

    for (final clinic in clinics) {
      final reqs = allReqs.where((r) => r.clinicId == clinic.id).toList();
      final target = reqs.fold(0, (sum, r) => sum + r.targetCount);
      final completed = reqs.fold(0, (sum, r) => sum + r.completedCount);
      final remaining = (target - completed).clamp(0, 99999);
      final percent = target > 0 ? ((completed / target) * 100).round() : 0;

      grandTarget += target;
      grandCompleted += completed;

      rows.add(
        pw.TableRow(
          children: <pw.Widget>[
            _tableCell(clinic.name),
            _tableCell('$target', align: pw.TextAlign.center),
            _tableCell('$completed', align: pw.TextAlign.center),
            _tableCell('$remaining', align: pw.TextAlign.center),
            _progressBarCell(completed, target, percent),
          ],
        ),
      );
    }

    // Total row
    final grandPercent = grandTarget > 0 ? ((grandCompleted / grandTarget) * 100).round() : 0;
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: <pw.Widget>[
          _tableCell('TOTAL ACADEMIC QUOTA', isBold: true),
          _tableCell('$grandTarget', align: pw.TextAlign.center, isBold: true),
          _tableCell('$grandCompleted', align: pw.TextAlign.center, isBold: true),
          _tableCell('${(grandTarget - grandCompleted).clamp(0, 99999)}', align: pw.TextAlign.center, isBold: true),
          _tableCell('$grandPercent%', align: pw.TextAlign.right, isBold: true),
        ],
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'DEPARTMENTAL QUOTA PROGRESS',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(1),
            4: pw.FlexColumnWidth(2),
          },
          children: rows,
        ),
      ],
    );
  }

  pw.Widget _progressBarCell(int completed, int target, int percent) {
    final double fraction = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: <pw.Widget>[
          pw.Text('$percent% ', style: const pw.TextStyle(fontSize: 8)),
          pw.Container(
            width: 40,
            height: 6,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: 40 * fraction,
                height: 6,
                decoration: pw.BoxDecoration(
                  color: fraction >= 1.0
                      ? PdfColors.green700
                      : fraction >= 0.5
                          ? PdfColors.teal700
                          : PdfColors.amber800,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEvaluatedCasesSection(
    List<CaseRecord> cases,
    Map<String, Patient> patientMap,
    Map<String, Requirement> requirementMap,
    Map<String, Clinic> clinicMap,
    DateFormat dateFormat,
  ) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.teal50),
        children: <pw.Widget>[
          _tableHeader('Case #'),
          _tableHeader('Patient Name'),
          _tableHeader('Procedure / Requirement'),
          _tableHeader('Status'),
          _tableHeader('Completion Date', align: pw.TextAlign.right),
        ],
      ),
    ];

    if (cases.isEmpty) {
      rows.add(
        pw.TableRow(
          children: <pw.Widget>[
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'No clinical cases recorded.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
            _tableCell(''),
            _tableCell(''),
            _tableCell(''),
            _tableCell(''),
          ],
        ),
      );
    } else {
      for (final c in cases) {
        final patientName = patientMap[c.patientId]?.name ?? 'Patient #${c.patientId}';
        final req = requirementMap[c.requirementId];
        final clinic = req != null ? clinicMap[req.clinicId] : null;
        final procTitle = req != null
            ? '${clinic?.name ?? ''} - ${req.title}'
            : 'Clinical Procedure';
        final completedDateStr =
            c.dateCompleted != null ? dateFormat.format(c.dateCompleted!) : 'Pending';

        rows.add(
          pw.TableRow(
            children: <pw.Widget>[
              _tableCell(c.id.length > 8 ? c.id.substring(0, 8) : c.id),
              _tableCell(patientName),
              _tableCell(procTitle),
              _tableCell(c.status),
              _tableCell(completedDateStr, align: pw.TextAlign.right),
            ],
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'EVALUATED CLINICAL CASES & PROCEDURES',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(1.2),
            1: pw.FlexColumnWidth(2.2),
            2: pw.FlexColumnWidth(3),
            3: pw.FlexColumnWidth(1.2),
            4: pw.FlexColumnWidth(1.8),
          },
          children: rows,
        ),
      ],
    );
  }

  pw.Widget _buildSupervisorySignOff() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'ACADEMIC FACULTY & SUPERVISORY ENDORSEMENT',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'I hereby certify that the student clinician named above has personally performed and satisfactorily '
            'completed the clinical procedures and quotas logged in this document under faculty supervision.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 28),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Container(width: 170, height: 1, color: PdfColors.grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Clinical Instructor Signature', style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 2),
                  pw.Text('Date: ________________________', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Container(width: 170, height: 1, color: PdfColors.grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Department Chair / Director', style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 2),
                  pw.Text('Date: ________________________', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Container(
                width: 70,
                height: 50,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, style: pw.BorderStyle.dashed),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text('FACULTY\nSEAL / STAMP',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _tableHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
      ),
    );
  }

  pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    final isRtl = hasArabicCharacters(text);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: isRtl && align == pw.TextAlign.left ? pw.TextAlign.right : align,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isBold ? PdfColors.black : PdfColors.grey800,
        ),
      ),
    );
  }

  /// Generates a standardized tabular CSV string suitable for spreadsheet grading.
  String generateCsvReport(QuotaReportData data) {
    AppLogger.info(
      'Generating CSV ${data.isDemoReport ? "DEMO showcase" : "live"} supervisory report for ${data.doctorName}',
    );
    final buffer = StringBuffer();
    // UTF-8 Byte Order Mark (BOM) so Microsoft Excel and spreadsheet tools display Arabic text properly
    buffer.write('\uFEFF');
    final dateFormat = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormat.format(data.generatedDate);

    final patientMap = <String, Patient>{
      for (final p in data.patients) p.id: p,
    };
    final requirementMap = <String, Requirement>{
      for (final r in data.requirements) r.id: r,
    };
    final clinicMap = <String, Clinic>{
      for (final c in data.clinics) c.id: c,
    };

    // Showcase Demo Report banner when generated in Guest Mode
    if (data.isDemoReport) {
      final isAr = data.localeCode.toLowerCase().startsWith('ar');
      buffer.writeln('"DEMO REPORT — FOR SHOWCASE ONLY (DEMO DATA)"');
      buffer.writeln('"STATUS","DEMO REPORT — SAMPLE DATA ONLY"');
      if (isAr) {
        buffer.writeln('"تنبيه","تقرير تجريبي — للعرض فقط (بيانات تجريبية)"');
      }
    }

    // Metadata header
    buffer.writeln('"DENTERA CLINICAL SUPERVISORY REPORT"');
    buffer.writeln('"Clinician Name",${_csvEscape(_formatDoctorName(data.doctorName))}');
    buffer.writeln('"Institution",${_csvEscape(data.university)}');
    buffer.writeln('"Academic Year",${_csvEscape(data.academicYear)}');
    buffer.writeln('"Date Range",${_csvEscape(data.dateRangeLabel)}');
    buffer.writeln('"Report Date",${_csvEscape(formattedDate)}');
    buffer.writeln();

    // Department quotas
    buffer.writeln('"DEPARTMENT QUOTAS"');
    buffer.writeln('"Department","Target Quota","Completed Cases","Remaining","Progress %"');
    for (final clinic in data.visibleClinics) {
      final reqs = data.requirements.where((r) => r.clinicId == clinic.id).toList();
      final target = reqs.fold(0, (sum, r) => sum + r.targetCount);
      final completed = reqs.fold(0, (sum, r) => sum + r.completedCount);
      final remaining = (target - completed).clamp(0, 99999);
      final percent = target > 0 ? ((completed / target) * 100).round() : 0;
      buffer.writeln(
        '${_csvEscape(clinic.name)},$target,$completed,$remaining,$percent%',
      );
    }
    buffer.writeln();

    // Evaluated cases
    buffer.writeln('"EVALUATED CASES & PROCEDURAL LOGS"');
    buffer.writeln('"Case ID","Patient ID","Patient Name","Department","Requirement","Status","Date Started","Date Completed"');
    for (final c in data.visibleCases) {
      final patientName = patientMap[c.patientId]?.name ?? 'Patient #${c.patientId}';
      final req = requirementMap[c.requirementId];
      final clinic = req != null ? clinicMap[req.clinicId] : null;
      final clinicName = clinic?.name ?? '';
      final reqTitle = req?.title ?? '';
      final dateStartedStr = dateFormat.format(c.dateStarted);
      final dateCompletedStr =
          c.dateCompleted != null ? dateFormat.format(c.dateCompleted!) : '';

      buffer.writeln(
        '${_csvEscape(c.id)},${_csvEscape(c.patientId)},${_csvEscape(patientName)},'
        '${_csvEscape(clinicName)},${_csvEscape(reqTitle)},${_csvEscape(c.status)},'
        '${_csvEscape(dateStartedStr)},${_csvEscape(dateCompletedStr)}',
      );
    }

    return buffer.toString();
  }

  String _csvEscape(String val) {
    final escaped = val.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Triggers system print and interactive preview modal for the generated report data.
  Future<void> previewAndPrintPdf(
    QuotaReportData data, {
    String title = 'Dentera_Quota_Report',
  }) async {
    final pdfBytes = await generatePdfReport(data);
    await previewAndPrintPdfBytes(pdfBytes, title: title);
  }

  /// Triggers system print and interactive preview modal for pre-generated PDF bytes.
  Future<void> previewAndPrintPdfBytes(
    Uint8List pdfBytes, {
    String title = 'Dentera_Quota_Report',
  }) async {
    AppLogger.info('Triggering Printing.layoutPdf for $title');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '$title.pdf',
    );
  }

  /// Invokes system share sheet for the generated report PDF.
  Future<void> sharePdf(
    QuotaReportData data, {
    String filename = 'dentera_quota_report.pdf',
  }) async {
    final pdfBytes = await generatePdfReport(data);
    await sharePdfBytes(pdfBytes, filename: filename);
  }

  /// Invokes system share sheet for pre-generated PDF bytes.
  Future<void> sharePdfBytes(
    Uint8List pdfBytes, {
    String filename = 'dentera_quota_report.pdf',
  }) async {
    AppLogger.info('Sharing PDF report via Printing.sharePdf ($filename)');
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }

  /// Writes CSV string to disk in application temp directory and shares via [SharePlus].
  Future<void> shareCsv(
    QuotaReportData data, {
    String filename = 'dentera_quota_report.csv',
  }) async {
    final csvContent = generateCsvReport(data);
    await shareCsvContent(csvContent, filename: filename);
  }

  /// Writes pre-generated CSV content to disk in application temp directory and shares via [SharePlus].
  Future<void> shareCsvContent(
    String csvContent, {
    String filename = 'dentera_quota_report.csv',
  }) async {
    AppLogger.info('Sharing CSV report via SharePlus ($filename)');
    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, filename);
    final file = File(filePath);
    await file.writeAsString(csvContent, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(filePath, mimeType: 'text/csv', name: filename),
        ],
        subject: 'Dentera Clinical Quota Report (CSV)',
      ),
    );
  }
}

/// Provider for [ReportGeneratorService].
final reportGeneratorServiceProvider =
    Provider<ReportGeneratorService>((ref) => const ReportGeneratorService());
