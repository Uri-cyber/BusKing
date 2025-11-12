import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/checklist_provider.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    await checklistProvider.loadChecklist();
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('הוסף פריט'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'שם הפריט',
                  hintText: 'תרופות',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(
                  labelText: 'אמוג\'י (אופציונלי)',
                  hintText: '💊',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
                final success = await checklistProvider.createItem(
                  nameController.text.trim(),
                  emojiController.text.trim().isEmpty ? null : emojiController.text.trim(),
                  null,
                );

                if (!mounted) return;

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('הפריט נוסף בהצלחה'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(checklistProvider.error ?? 'שגיאה בהוספת פריט'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              child: const Text('הוסף'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('צ\'קליסט שלי'),
      ),
      body: Consumer<ChecklistProvider>(
        builder: (context, checklistProvider, _) {
          if (checklistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (checklistProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.checklist,
                    size: 80,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 20),
                  const Text('אין פריטים בצ\'קליסט', style: AppTheme.headline3),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('הוסף פריט'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: checklistProvider.items.length,
            itemBuilder: (context, index) {
              final item = checklistProvider.items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: item.emoji != null
                      ? Text(
                          item.emoji!,
                          style: const TextStyle(fontSize: 32),
                        )
                      : const Icon(Icons.check_box_outline_blank),
                  title: Text(item.itemName),
                  subtitle: item.context != null ? Text('הקשר: ${item.context}') : null,
                  trailing: item.isDefault
                      ? const Chip(
                          label: Text('ברירת מחדל'),
                          padding: EdgeInsets.zero,
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('מחק פריט'),
                                content: const Text('האם אתה בטוח?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('ביטול'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('מחק'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await checklistProvider.deleteItem(item.id);
                            }
                          },
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
