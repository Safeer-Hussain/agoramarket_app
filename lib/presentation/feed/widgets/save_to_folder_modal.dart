import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/video_pitch.dart';
import '../video_feed_provider.dart';

class SaveToFolderModal extends StatefulWidget {
  final VideoPitch pitch;

  const SaveToFolderModal({super.key, required this.pitch});

  static Future<void> show(BuildContext context, VideoPitch pitch) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveToFolderModal(pitch: pitch),
    );
  }

  @override
  State<SaveToFolderModal> createState() => _SaveToFolderModalState();
}

class _SaveToFolderModalState extends State<SaveToFolderModal> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _newTagController = TextEditingController();

  String? _selectedFolderId;
  final Set<String> _selectedTags = {};

  static const List<String> _suggestedTags = [
    'Architecture',
    'Flutter',
    'Senior Lead',
    'Fintech',
    'High Throughput',
    'Custom Canvas',
    'Offline First',
    'Top 1%',
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<VideoFeedProvider>(context, listen: false);
    final savedFolders = provider.getFoldersForPitch(widget.pitch.id);
    if (savedFolders.isNotEmpty) {
      _selectedFolderId = savedFolders.first;
    } else if (provider.folders.isNotEmpty) {
      _selectedFolderId = provider.folders.first.id;
    }
    _selectedTags.addAll(provider.getTagsForPitch(widget.pitch.id));
    if (_selectedTags.isEmpty && widget.pitch.skills.isNotEmpty) {
      _selectedTags.addAll(widget.pitch.skills.take(2));
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  void _addNewTag() {
    final text = _newTagController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _selectedTags.add(text);
        _newTagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final provider = Provider.of<VideoFeedProvider>(context);
    final folders = provider.folders;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bookmark_add_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save to Collection',
                          style: TextStyle(
                            fontSize: isLandscape ? 15 : 17,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          widget.pitch.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Choose Collection Folder
              Text(
                'Target Collection Folder',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              if (folders.isEmpty)
                Text(
                  'No collection folders created yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: folders.map((folder) {
                    final isSel = _selectedFolderId == folder.id;
                    return ChoiceChip(
                      avatar: Icon(
                        _getIconData(folder.iconName),
                        size: 16,
                        color: isSel
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                      ),
                      label: Text(
                        '${folder.name} (${folder.pitchCount})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedFolderId = folder.id);
                        }
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              // 2. Tagging Taxonomy
              Text(
                'Taxonomy Tags',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._suggestedTags.map((tag) {
                    final isSel = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSel
                              ? colorScheme.onSecondary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: colorScheme.secondary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }),
                  ..._selectedTags
                      .where((t) => !_suggestedTags.contains(t))
                      .map((customTag) {
                        return InputChip(
                          label: Text(
                            customTag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondary,
                            ),
                          ),
                          selected: true,
                          selectedColor: colorScheme.secondary,
                          onDeleted: () {
                            setState(() => _selectedTags.remove(customTag));
                          },
                        );
                      }),
                ],
              ),
              const SizedBox(height: 8),

              // Inline custom tag field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTagController,
                      onSubmitted: (_) => _addNewTag(),
                      decoration: InputDecoration(
                        hintText: 'Add custom tag (e.g. GraphQL, DevOps)...',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _addNewTag,
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: 'Add Tag',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Notes Field
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Recruiter / Architect Notes (Optional)',
                  hintText: 'Evaluation notes, pitch highlights, sprint fit...',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _selectedFolderId == null
                      ? null
                      : () async {
                          final selectedFolder = folders.firstWhere(
                            (f) => f.id == _selectedFolderId,
                          );

                          await provider.savePitchToFolder(
                            pitchId: widget.pitch.id,
                            folderId: _selectedFolderId!,
                            tags: _selectedTags.toList(),
                            notes: _notesController.text.trim(),
                          );

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            AppFeedback.showSuccess(
                              context,
                              'Saved to "${selectedFolder.name}" with ${_selectedTags.length} tags',
                            );
                          }
                        },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text(
                    'Save to Collection Folder',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'code':
        return Icons.code_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'security':
        return Icons.security_rounded;
      default:
        return Icons.folder_rounded;
    }
  }
}
