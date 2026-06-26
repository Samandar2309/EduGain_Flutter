import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/ui/error_handling.dart';
import '../application/providers.dart';

class VocabSetListScreen extends ConsumerWidget {
  const VocabSetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(vocabSetsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary')),
      body: sets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Yuklab bo\'lmadi')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Hozircha to\'plamlar yo\'q'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final s = list[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(child: Text(s.cefrLevel)),
                      title: Text(
                        s.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(s.category),
                      trailing: Icon(
                        s.isLocked
                            ? Icons.lock_rounded
                            : Icons.chevron_right_rounded,
                      ),
                      onTap: () {
                        if (s.isLocked) {
                          showApiError(
                            context,
                            const ApiException(
                              code: 'PAYWALL',
                              message: '',
                              statusCode: 402,
                            ),
                          );
                        } else {
                          context.push('/vocabulary/study', extra: s);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
