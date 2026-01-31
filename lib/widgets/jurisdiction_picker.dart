import 'package:flutter/material.dart';

import '../services/municipalities_database.dart';
import '../services/recent_municipalities_service.dart';

/// Widget avanzato per selezionare la giurisdizione con comuni recenti
class JurisdictionPicker extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final void Function(Municipality)? onSelected;

  const JurisdictionPicker({
    super.key,
    required this.controller,
    this.decoration,
    this.onSelected,
  });

  @override
  State<JurisdictionPicker> createState() => _JurisdictionPickerState();
}

class _JurisdictionPickerState extends State<JurisdictionPicker> {
  List<Municipality> _recentMunicipalities = [];
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadRecentMunicipalities();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && widget.controller.text.isEmpty) {
      _showRecentOverlay();
    } else if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  Future<void> _loadRecentMunicipalities() async {
    final recent = await RecentMunicipalitiesService.getRecentMunicipalities();
    if (mounted) {
      setState(() => _recentMunicipalities = recent);
    }
  }

  void _showRecentOverlay() {
    if (_recentMunicipalities.isEmpty) return;
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(12),
            child: _buildRecentList(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildRecentList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white10),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Comuni recenti',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await RecentMunicipalitiesService.clearHistory();
                    await _loadRecentMunicipalities();
                    _removeOverlay();
                  },
                  child: const Text(
                    'Cancella',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _recentMunicipalities.length,
              itemBuilder: (context, index) {
                final municipality = _recentMunicipalities[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    municipality.isProvincialCapital
                        ? Icons.location_city
                        : Icons.place,
                    color: Colors.white54,
                    size: 20,
                  ),
                  title: Text(
                    municipality.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${municipality.region} (${municipality.provinceCode})',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  onTap: () => _selectMunicipality(municipality),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectMunicipality(Municipality municipality) {
    widget.controller.text = municipality.name;
    RecentMunicipalitiesService.recordUsage(municipality.name);
    widget.onSelected?.call(municipality);
    _removeOverlay();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Autocomplete<Municipality>(
        initialValue: TextEditingValue(text: widget.controller.text),
        optionsBuilder: (textEditingValue) {
          _removeOverlay();
          if (textEditingValue.text.isEmpty) {
            return const Iterable<Municipality>.empty();
          }
          return MunicipalitiesDatabase.search(textEditingValue.text).take(5);
        },
        displayStringForOption: (municipality) => municipality.name,
        onSelected: (municipality) {
          widget.controller.text = municipality.name;
          RecentMunicipalitiesService.recordUsage(municipality.name);
          widget.onSelected?.call(municipality);
        },
        fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
          // Sync controllers
          textController.addListener(() {
            if (widget.controller.text != textController.text) {
              widget.controller.text = textController.text;
            }
            // Nascondi overlay recenti quando si digita
            if (textController.text.isNotEmpty) {
              _removeOverlay();
            }
          });

          // Use our focus node for recent tracking
          focusNode.addListener(() {
            if (focusNode.hasFocus && textController.text.isEmpty && _recentMunicipalities.isNotEmpty) {
              _showRecentOverlay();
            } else if (!focusNode.hasFocus) {
              _removeOverlay();
            }
          });

          return TextField(
            controller: textController,
            focusNode: focusNode,
            style: const TextStyle(color: Colors.white),
            decoration: (widget.decoration ?? const InputDecoration()).copyWith(
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_recentMunicipalities.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.white38, size: 20),
                      onPressed: () {
                        textController.clear();
                        FocusScope.of(context).requestFocus(focusNode);
                        _showRecentOverlay();
                      },
                      tooltip: 'Comuni recenti',
                    ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white38),
                ],
              ),
            ),
            onSubmitted: (_) => onSubmitted(),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 280),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final municipality = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        municipality.isProvincialCapital
                            ? Icons.location_city
                            : Icons.place,
                        color: Colors.white54,
                        size: 20,
                      ),
                      title: Text(
                        municipality.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${municipality.region} (${municipality.provinceCode})',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      onTap: () => onSelected(municipality),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget chip per mostrare i comuni frequenti
class FrequentMunicipalitiesChips extends StatefulWidget {
  final void Function(Municipality) onSelected;

  const FrequentMunicipalitiesChips({
    super.key,
    required this.onSelected,
  });

  @override
  State<FrequentMunicipalitiesChips> createState() => _FrequentMunicipalitiesChipsState();
}

class _FrequentMunicipalitiesChipsState extends State<FrequentMunicipalitiesChips> {
  List<Municipality> _frequentMunicipalities = [];

  @override
  void initState() {
    super.initState();
    _loadFrequent();
  }

  Future<void> _loadFrequent() async {
    final frequent = await RecentMunicipalitiesService.getMostUsedMunicipalities(limit: 4);
    if (mounted) {
      setState(() => _frequentMunicipalities = frequent);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_frequentMunicipalities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comuni frequenti:',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: _frequentMunicipalities.map((m) {
            return ActionChip(
              avatar: Icon(
                m.isProvincialCapital ? Icons.location_city : Icons.place,
                size: 14,
                color: Colors.white54,
              ),
              label: Text(
                m.name,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              backgroundColor: const Color(0xFF1E2636),
              side: BorderSide.none,
              onPressed: () {
                RecentMunicipalitiesService.recordUsage(m.name);
                widget.onSelected(m);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
