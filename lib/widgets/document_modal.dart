import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/document_analyzer_models.dart';
import '../services/document_export_service.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';
import 'next_steps_guide.dart';

/// Modal for displaying generated documents with PDF/Share/Copy actions
class DocumentModal extends StatefulWidget {
  final DocumentResponse document;
  final String caseReference;
  final String jurisdiction;
  final double amount;
  final DateTime issueDate;

  const DocumentModal({
    super.key,
    required this.document,
    required this.caseReference,
    required this.jurisdiction,
    required this.amount,
    required this.issueDate,
  });

  @override
  State<DocumentModal> createState() => _DocumentModalState();
}

class _DocumentModalState extends State<DocumentModal> {
  bool _isLoadingPdf = false;
  bool _isLoadingShare = false;
  bool _isLoadingTxt = false;

  Future<void> _handlePdfTap() async {
    if (_isLoadingPdf) return;

    setState(() => _isLoadingPdf = true);

    try {
      debugPrint('[DocumentModal] Generating PDF...');
      final pdfBytes = await PdfService.generateContestationPdf(
        document: widget.document,
        caseReference: widget.caseReference,
        jurisdiction: widget.jurisdiction,
        amount: widget.amount,
        issueDate: widget.issueDate,
      );

      final filename = 'contestazione_${widget.caseReference.replaceAll(RegExp(r'[^\w]'), '_')}.pdf';
      debugPrint('[DocumentModal] Sharing PDF: $filename');

      await PdfService.sharePdf(pdfBytes: pdfBytes, filename: filename);
      debugPrint('[DocumentModal] PDF shared successfully');
    } catch (e, stack) {
      debugPrint('[DocumentModal] PDF error: $e');
      debugPrint('[DocumentModal] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPdf = false);
      }
    }
  }

  Future<void> _handleShareTap(BuildContext buttonContext) async {
    if (_isLoadingShare) return;

    setState(() => _isLoadingShare = true);

    try {
      debugPrint('[DocumentModal] Sharing document...');

      // Get button position for iPad share sheet
      Rect? sharePosition;
      try {
        final box = buttonContext.findRenderObject() as RenderBox?;
        if (box != null) {
          sharePosition = box.localToGlobal(Offset.zero) & box.size;
        }
      } catch (_) {
        // Ignore render object errors
      }

      await ShareService.shareDocument(
        widget.document,
        sharePositionOrigin: sharePosition,
      );
      debugPrint('[DocumentModal] Document shared successfully');
    } catch (e, stack) {
      debugPrint('[DocumentModal] Share error: $e');
      debugPrint('[DocumentModal] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore condivisione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingShare = false);
      }
    }
  }

  Future<void> _handleCopyTap() async {
    final text = '${widget.document.title}\n\n${widget.document.body}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Testo copiato negli appunti'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleTxtTap() async {
    if (_isLoadingTxt) return;

    setState(() => _isLoadingTxt = true);

    try {
      debugPrint('[DocumentModal] Exporting as TXT...');
      final result = await DocumentExportService.share(
        title: widget.document.title,
        body: widget.document.body,
        format: ExportFormat.txt,
        caseReference: widget.caseReference,
        jurisdiction: widget.jurisdiction,
        amount: widget.amount,
        issueDate: widget.issueDate,
      );

      if (!result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Errore esportazione TXT'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        debugPrint('[DocumentModal] TXT exported successfully');
      }
    } catch (e, stack) {
      debugPrint('[DocumentModal] TXT error: $e');
      debugPrint('[DocumentModal] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore TXT: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTxt = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              _buildHeader(),
              const SizedBox(height: 16),
              // Action buttons
              _buildActionButtons(),
              const SizedBox(height: 16),
              // Document body
              Flexible(child: _buildDocumentBody()),
              const SizedBox(height: 16),
              // Footer buttons
              _buildFooterButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.description, color: Colors.greenAccent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.document.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Generato il ${DateFormat('dd/MM/yyyy HH:mm', 'it_IT').format(DateTime.now())}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: _isLoadingPdf ? null : Icons.picture_as_pdf,
              label: 'PDF',
              color: Colors.redAccent,
              isLoading: _isLoadingPdf,
              onTap: _handlePdfTap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildActionButton(
              icon: _isLoadingTxt ? null : Icons.text_snippet,
              label: 'TXT',
              color: Colors.tealAccent,
              isLoading: _isLoadingTxt,
              onTap: _handleTxtTap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Builder(
              builder: (buttonContext) => _buildActionButton(
                icon: _isLoadingShare ? null : Icons.share,
                label: 'Condividi',
                color: Colors.blueAccent,
                isLoading: _isLoadingShare,
                onTap: () => _handleShareTap(buttonContext),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildActionButton(
              icon: Icons.copy,
              label: 'Copia',
              color: Colors.amber,
              onTap: _handleCopyTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (isLoading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentBody() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guide: come procedere
            NextStepsGuide(
              fineDate: widget.issueDate,
              onNeedPecHelp: () {
                showDialog(
                  context: context,
                  builder: (_) => const PecProvidersDialog(),
                );
              },
            ),
            const SizedBox(height: 16),
            // Document header
            Row(
              children: [
                const Icon(Icons.article_outlined, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Bozza del documento',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Da personalizzare',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              widget.document.body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            if (widget.document.recommendations.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildRecommendations(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Azioni raccomandate',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...widget.document.recommendations.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Chiudi',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(widget.document),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Salva nello storico',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
