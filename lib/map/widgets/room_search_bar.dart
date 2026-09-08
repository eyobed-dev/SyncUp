/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Reusable UI component for the room_search_bar interface.
 */

import 'package:flutter/material.dart';
import '../../theme/sync_up_colors.dart';
import '../models/fit_room.dart';
import '../services/fit_map_data_service.dart';

class RoomSearchBar extends StatefulWidget {
  final ValueChanged<FitRoom> onRoomSelected;
  final VoidCallback? onClear;
  final String hintText;
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final bool showSuggestionsInline;
  final String? initialValue;

  const RoomSearchBar({
    super.key,
    required this.onRoomSelected,
    this.onClear,
    this.hintText = 'Search room, lab, or office (e.g. C201, A112)...',
    this.controller,
    this.prefixIcon,
    this.showSuggestionsInline = true,
    this.initialValue,
  });

  @override
  State<RoomSearchBar> createState() => _RoomSearchBarState();
}

class _RoomSearchBarState extends State<RoomSearchBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<FitRoom> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      widget.onClear?.call();
      return;
    }

    final results = FitMapDataService.instance.search(query, limit: 8);
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty && _focusNode.hasFocus;
    });
  }

  void _selectSuggestion(FitRoom room) {
    _controller.text = room.id;
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
    widget.onRoomSelected(room);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TapRegion(
      onTapOutside: (_) {
        if (_showSuggestions) {
          setState(() {
            _showSuggestions = false;
          });
        }
        _focusNode.unfocus();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
          height: 48,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onTap: () {
              if (_controller.text.trim().isNotEmpty && _suggestions.isNotEmpty) {
                setState(() {
                  _showSuggestions = true;
                });
              }
            },
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: colors.textSecondary.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              prefixIcon: widget.prefixIcon ??
                  Icon(
                    Icons.search_rounded,
                    color: colors.textSecondary,
                    size: 20,
                  ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _showSuggestions = false;
                        });
                        widget.onClear?.call();
                        _focusNode.unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        if (widget.showSuggestionsInline && _showSuggestions && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: colors.surface,
            surfaceTintColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: colors.border,
                ),
                itemBuilder: (context, index) {
                  final room = _suggestions[index];
                  return ListTile(
                    dense: true,
                    onTap: () => _selectSuggestion(room),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        room.id,
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      room.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        room.floorLabel,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ], // closes spread array
      ], // closes children array
    ), // closes Column
    ); // closes TapRegion
  }
}
