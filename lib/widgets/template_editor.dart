import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/custom_template_service.dart';

/// Widget per visualizzare e gestire i template
class TemplateManager extends StatefulWidget {
  final String? initialCategory;
  final Function(CustomTemplate)? onTemplateSelected;

  const TemplateManager({
    super.key,
    this.initialCategory,
    this.onTemplateSelected,
  });

  @override
  State<TemplateManager> createState() => _TemplateManagerState();
}

class _TemplateManagerState extends State<TemplateManager> {
  List<CustomTemplate> _templates = [];
  String _selectedCategory = 'prefetto';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'prefetto';
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final templates = await CustomTemplateService.loadTemplates();
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _isLoading = false;
    });
  }

  List<CustomTemplate> get _filteredTemplates =>
      _templates.where((t) => t.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151C26), Color(0xFF0D1218)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildCategoryTabs(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildTemplateList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description, color: Colors.amber, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Template Ricorso',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              Text(
                'Personalizza o crea nuovi modelli',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _showCreateTemplateDialog,
          icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
          tooltip: 'Nuovo template',
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TemplateCategory.values.map((category) {
          final isSelected = category.id == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = category.id),
              backgroundColor: const Color(0xFF1E2636),
              selectedColor: Colors.amber.withAlpha(40),
              labelStyle: TextStyle(
                color: isSelected ? Colors.amber : Colors.white70,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected ? Colors.amber.withAlpha(100) : Colors.transparent,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTemplateList() {
    if (_filteredTemplates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Text(
          'Nessun template in questa categoria',
          style: TextStyle(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: _filteredTemplates.map((template) {
        final isBuiltIn = template.id.startsWith('builtin_');
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: template.isDefault
                  ? Colors.amber.withAlpha(60)
                  : Colors.white.withAlpha(10),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(
              isBuiltIn ? Icons.lock_outline : Icons.edit_document,
              color: isBuiltIn ? Colors.white38 : Colors.amber,
              size: 20,
            ),
            title: Text(
              template.name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              isBuiltIn ? 'Template predefinito' : 'Modificato: ${_formatDate(template.updatedAt)}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onTemplateSelected != null)
                  TextButton(
                    onPressed: () => widget.onTemplateSelected!(template),
                    child: const Text('Usa', style: TextStyle(color: Colors.amber)),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                  color: const Color(0xFF1A1F2E),
                  onSelected: (action) => _handleTemplateAction(action, template),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text('Visualizza', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    if (!isBuiltIn)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.white70, size: 18),
                            SizedBox(width: 8),
                            Text('Modifica', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text('Duplica', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.upload, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text('Esporta', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    if (!isBuiltIn)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text('Elimina', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _handleTemplateAction(String action, CustomTemplate template) async {
    switch (action) {
      case 'view':
        await _showTemplatePreview(template);
        break;
      case 'edit':
        await _showEditTemplateDialog(template);
        break;
      case 'duplicate':
        await CustomTemplateService.duplicateTemplate(template);
        await _loadTemplates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template duplicato')),
          );
        }
        break;
      case 'export':
        final json = CustomTemplateService.exportTemplate(template);
        await Clipboard.setData(ClipboardData(text: json));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template copiato negli appunti (JSON)')),
          );
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F2E),
            title: const Text('Elimina template', style: TextStyle(color: Colors.white)),
            content: Text(
              'Vuoi eliminare "${template.name}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Elimina', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await CustomTemplateService.deleteTemplate(template.id);
          await _loadTemplates();
        }
        break;
    }
  }

  Future<void> _showTemplatePreview(CustomTemplate template) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Oggetto: ${template.subject}',
                  style: const TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      template.body,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPlaceholderLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderLegend() {
    return ExpansionTile(
      title: const Text(
        'Placeholder disponibili',
        style: TextStyle(color: Colors.white70, fontSize: 13),
      ),
      iconColor: Colors.white54,
      collapsedIconColor: Colors.white54,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: CustomTemplate.availablePlaceholders.map((p) {
            return Tooltip(
              message: '${p.description}\nEsempio: ${p.example}',
              child: Chip(
                label: Text(
                  p.key,
                  style: const TextStyle(fontSize: 10, color: Colors.amber),
                ),
                backgroundColor: Colors.amber.withAlpha(20),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _showCreateTemplateDialog() async {
    final result = await showDialog<CustomTemplate>(
      context: context,
      builder: (context) => TemplateEditorDialog(
        category: _selectedCategory,
      ),
    );
    if (result != null) {
      await CustomTemplateService.saveTemplate(result);
      await _loadTemplates();
    }
  }

  Future<void> _showEditTemplateDialog(CustomTemplate template) async {
    final result = await showDialog<CustomTemplate>(
      context: context,
      builder: (context) => TemplateEditorDialog(
        category: template.category,
        existingTemplate: template,
      ),
    );
    if (result != null) {
      await CustomTemplateService.saveTemplate(result);
      await _loadTemplates();
    }
  }
}

/// Dialog per creare/modificare template
class TemplateEditorDialog extends StatefulWidget {
  final String category;
  final CustomTemplate? existingTemplate;

  const TemplateEditorDialog({
    super.key,
    required this.category,
    this.existingTemplate,
  });

  @override
  State<TemplateEditorDialog> createState() => _TemplateEditorDialogState();
}

class _TemplateEditorDialogState extends State<TemplateEditorDialog> {
  late TextEditingController _nameController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingTemplate?.name ?? '',
    );
    _subjectController = TextEditingController(
      text: widget.existingTemplate?.subject ?? '',
    );
    _bodyController = TextEditingController(
      text: widget.existingTemplate?.body ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTemplate != null;

    return Dialog(
      backgroundColor: const Color(0xFF0F1117),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  isEditing ? 'Modifica Template' : 'Nuovo Template',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Nome template'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Oggetto'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _bodyController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: _inputDecoration('Corpo del template').copyWith(
                  hintText: 'Usa i placeholder come [NOME_COGNOME], [IMPORTO], etc.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickInsertBar(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveTemplate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isEditing ? 'Salva modifiche' : 'Crea template'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1A1F2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildQuickInsertBar() {
    final commonPlaceholders = [
      '[NOME_COGNOME]',
      '[IMPORTO]',
      '[NUMERO_VERBALE]',
      '[DATA_VERBALE]',
      '[MOTIVAZIONI]',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text(
            'Inserisci: ',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          ...commonPlaceholders.map((p) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ActionChip(
                  label: Text(p, style: const TextStyle(fontSize: 10)),
                  onPressed: () => _insertPlaceholder(p),
                  backgroundColor: const Color(0xFF1A1F2E),
                  labelStyle: const TextStyle(color: Colors.amber),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              )),
        ],
      ),
    );
  }

  void _insertPlaceholder(String placeholder) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      placeholder,
    );
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + placeholder.length,
      ),
    );
  }

  void _saveTemplate() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome per il template')),
      );
      return;
    }

    final now = DateTime.now();
    final template = CustomTemplate(
      id: widget.existingTemplate?.id ?? 'custom_${now.millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: widget.category,
      subject: _subjectController.text.trim(),
      body: _bodyController.text,
      createdAt: widget.existingTemplate?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.pop(context, template);
  }
}
