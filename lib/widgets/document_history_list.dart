import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/document_history.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';

class DocumentHistoryList extends StatefulWidget {
  final List<DocumentHistoryEntry> history;
  final void Function(DocumentHistoryEntry)? onDelete;
  final String? caseReference;
  final String? jurisdiction;
  final double? amount;
  final DateTime? issueDate;

  const DocumentHistoryList({
    super.key,
    required this.history,
    this.onDelete,
    this.caseReference,
    this.jurisdiction,
    this.amount,
    this.issueDate,
  });

  @override
  State<DocumentHistoryList> createState() => _DocumentHistoryListState();
}

class _DocumentHistoryListState extends State<DocumentHistoryList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOrder = 'newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocumentHistoryEntry> get _filteredHistory {
    var filtered = widget.history.where((entry) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return entry.document.title.toLowerCase().contains(query) ||
          entry.document.body.toLowerCase().contains(query);
    }).toList();

    if (_sortOrder == 'oldest') {
      filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else {
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHistory;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'it_IT');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF12161E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cerca per titolo o contenuto...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF0A0E14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 10),
              // Filter row
              Row(
                children: [
                  Text(
                    '${filtered.length} document${filtered.length == 1 ? 'o' : 'i'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Spacer(),
                  // Sort dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _sortOrder,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: const Color(0xFF1A1F2E),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      icon: const Icon(Icons.sort, color: Colors.white54, size: 16),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Più recenti')),
                        DropdownMenuItem(value: 'oldest', child: Text('Più vecchi')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _sortOrder = value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Results
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF12161E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(Icons.search_off, color: Colors.white24, size: 48),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isEmpty
                      ? 'Nessun documento nello storico'
                      : 'Nessun risultato per "$_searchQuery"',
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...filtered.map((entry) => _buildHistoryCard(entry, dateFormat)),
      ],
    );
  }

  Widget _buildHistoryCard(DocumentHistoryEntry entry, DateFormat dateFormat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F2E), Color(0xFF12161E)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined, color: Colors.greenAccent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.document.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(entry.timestamp),
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 20),
                    onPressed: () => _confirmDelete(entry),
                    tooltip: 'Elimina',
                  ),
              ],
            ),
          ),
          // Body preview
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Text(
              entry.document.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                _buildActionChip(
                  icon: Icons.copy,
                  label: 'Copia',
                  onTap: () => _copyToClipboard(entry),
                ),
                const SizedBox(width: 6),
                _buildActionChip(
                  icon: Icons.share,
                  label: 'Condividi',
                  onTap: () => _shareDocument(entry),
                ),
                const SizedBox(width: 6),
                _buildActionChip(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  onTap: () => _exportPdf(entry),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showFullDocument(entry),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Leggi tutto', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(DocumentHistoryEntry entry) {
    final text = '${entry.document.title}\n\n${entry.document.body}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testo copiato negli appunti'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareDocument(DocumentHistoryEntry entry) async {
    await ShareService.shareDocument(entry.document);
  }

  Future<void> _exportPdf(DocumentHistoryEntry entry) async {
    try {
      final pdfBytes = await PdfService.generateContestationPdf(
        document: entry.document,
        caseReference: widget.caseReference ?? 'N/A',
        jurisdiction: widget.jurisdiction ?? 'N/A',
        amount: widget.amount ?? 0,
        issueDate: widget.issueDate ?? entry.timestamp,
      );
      final filename = 'contestazione_${entry.timestamp.millisecondsSinceEpoch}.pdf';
      await PdfService.sharePdf(pdfBytes: pdfBytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore generazione PDF: $e')),
        );
      }
    }
  }

  void _confirmDelete(DocumentHistoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text('Elimina documento'),
        content: const Text('Vuoi eliminare questo documento dallo storico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call(entry);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _showFullDocument(DocumentHistoryEntry entry) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'it_IT');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.greenAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.document.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          dateFormat.format(entry.timestamp),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      entry.document.body,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    if (entry.document.recommendations.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withAlpha(40)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Azioni raccomandate',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...entry.document.recommendations.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withAlpha(30),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${e.key + 1}',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(entry),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copia'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareDocument(entry),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Condividi'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportPdf(entry),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
