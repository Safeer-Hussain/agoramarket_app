import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/video_pitch.dart';
import '../video_feed_provider.dart';

class BookmarkCollectionsSheet extends StatefulWidget {
  const BookmarkCollectionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final provider = Provider.of<VideoFeedProvider>(context, listen: false);
    provider.loadBookmarkCollections();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BookmarkCollectionsSheet(),
    );
  }

  @override
  State<BookmarkCollectionsSheet> createState() =>
      _BookmarkCollectionsSheetState();
}

class _BookmarkCollectionsSheetState extends State<BookmarkCollectionsSheet> {
  bool _isReordering = false;

  void _showCreateFolderDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedIcon = 'folder';

    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              'New Bookmark Collection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Collection Name',
                      hintText: 'e.g. AI Researchers, Senior Leads...',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Purpose and candidate criteria...',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Select Collection Icon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          'folder',
                          'code',
                          'payments',
                          'terminal',
                          'rocket',
                          'security',
                        ].map((iconKey) {
                          final isSel = selectedIcon == iconKey;
                          return ChoiceChip(
                            avatar: Icon(
                              _getIconData(iconKey),
                              size: 16,
                              color: isSel
                                  ? colorScheme.onPrimary
                                  : colorScheme.primary,
                            ),
                            label: Text(iconKey),
                            selected: isSel,
                            selectedColor: colorScheme.primary,
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() => selectedIcon = iconKey);
                              }
                            },
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  final provider = Provider.of<VideoFeedProvider>(
                    context,
                    listen: false,
                  );
                  await provider.createFolder(
                    nameController.text.trim(),
                    descController.text.trim(),
                    selectedIcon,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Create Folder'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final provider = Provider.of<VideoFeedProvider>(context);

    final folders = provider.folders;
    final allTags = provider.allUniqueTags;
    final bookmarkedPitches = provider.bookmarkedPitches;

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
                      Icons.folder_special_rounded,
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
                          'Bookmark Collections & Taxonomy',
                          style: TextStyle(
                            fontSize: isLandscape ? 15 : 17,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Organized talent pipelines and custom taxonomy tags',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isReordering
                          ? Icons.check_circle_outline_rounded
                          : Icons.sort_rounded,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                    tooltip: _isReordering
                        ? 'Done Reordering'
                        : 'Reorder Collections',
                    onPressed: () {
                      setState(() => _isReordering = !_isReordering);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.create_new_folder_outlined,
                      size: 20,
                    ),
                    tooltip: 'New Collection Folder',
                    color: colorScheme.primary,
                    onPressed: () => _showCreateFolderDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Collections View (Reorderable List or Horizontal Filter Strip)
              if (_isReordering) ...[
                Text(
                  'Drag and drop collections to reorder',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: folders.length,
                  onReorderItem: (oldIndex, newIndex) {
                    provider.reorderFolders(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return ListTile(
                      key: ValueKey(folder.id),
                      leading: Icon(
                        _getIconData(folder.iconName),
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        folder.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${folder.pitchCount} saved pitches',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: colorScheme.error,
                              size: 18,
                            ),
                            tooltip: 'Delete Collection',
                            onPressed: () => provider.deleteFolder(folder.id),
                          ),
                          const Icon(Icons.drag_handle_rounded, size: 20),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Folder Choice Filter Chips
                Text(
                  'Collections',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(
                        'All Collections (${provider.bookmarks.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: provider.selectedFolderId == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: provider.selectedFolderId == null
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: provider.selectedFolderId == null,
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      onSelected: (val) {
                        if (val) provider.selectFolder(null);
                      },
                    ),
                    ...folders.map((folder) {
                      final isSel = provider.selectedFolderId == folder.id;
                      return ChoiceChip(
                        avatar: Icon(
                          _getIconData(folder.iconName),
                          size: 14,
                          color: isSel
                              ? colorScheme.onPrimary
                              : colorScheme.primary,
                        ),
                        label: Text(
                          '${folder.name} (${folder.pitchCount})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSel
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        onSelected: (val) {
                          provider.selectFolder(val ? folder.id : null);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 14),

                // Taxonomy Tag Filter Bar
                if (allTags.isNotEmpty) ...[
                  Text(
                    'Filter by Tag',
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
                      FilterChip(
                        label: Text(
                          'All Tags',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: provider.selectedTag == null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: provider.selectedTag == null
                                ? colorScheme.onSecondary
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: provider.selectedTag == null,
                        selectedColor: colorScheme.secondary,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        onSelected: (val) {
                          if (val) provider.selectTag(null);
                        },
                      ),
                      ...allTags.map((tag) {
                        final isSel = provider.selectedTag == tag;
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
                            provider.selectTag(val ? tag : null);
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Pitches in collection list
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved Video Pitches (${bookmarkedPitches.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (bookmarkedPitches.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bookmark_border_rounded,
                            size: 36,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No Pitches Found',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'No bookmarked pitches match the selected filters.',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookmarkedPitches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final pitch = bookmarkedPitches[index];
                      final tags = provider.getTagsForPitch(pitch.id);

                      return _buildPitchCard(
                        context,
                        pitch,
                        tags,
                        provider,
                        colorScheme,
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPitchCard(
    BuildContext context,
    VideoPitch pitch,
    List<String> tags,
    VideoFeedProvider provider,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.primaryContainer,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/thumb_mobile_arch.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pitch.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pitch.creatorName} • \$${pitch.hourlyRate.toStringAsFixed(0)}/hr',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.bookmark_remove_rounded,
                  color: colorScheme.error,
                  size: 20,
                ),
                tooltip: 'Remove Bookmark',
                onPressed: () async {
                  await provider.toggleBookmark(pitch.id);
                  if (context.mounted) {
                    AppFeedback.showSuccess(
                      context,
                      'Pitch removed from saved collections',
                    );
                  }
                },
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: tags.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _getIconData(String name) {
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
