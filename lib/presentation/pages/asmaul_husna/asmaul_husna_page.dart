import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/asmaul_husna_model.dart';
import '../../providers/asmaul_husna_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

class AsmaulHusnaPage extends ConsumerWidget {
  const AsmaulHusnaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final namesAsync = ref.watch(asmaulHusnaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Асмоул Ҳусно'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              GoRouter.of(context).go('/');
            }
          },
        ),
      ),
      body: namesAsync.when(
        data: (names) => _buildNamesList(context, names),
        loading: () => const LoadingListWidget(
          itemCount: 10,
          itemHeight: 120,
        ),
        error: (error, stackTrace) => CustomErrorWidget(
          title: 'Хатоги дар боргирӣ',
          message: 'Асмоул Ҳусноро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
          onRetry: () {
            ref.invalidate(asmaulHusnaProvider);
          },
        ),
      ),
    );
  }

  Widget _buildNamesList(BuildContext context, List<AsmaulHusnaModel> names) {
    if (names.isEmpty) {
      return const Center(
        child: Text('Асмоул Ҳусно ёфт нашуд'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: names.length,
      itemBuilder: (context, index) {
        final name = names[index];
        return _NameCard(name: name);
      },
    );
  }
}

class _NameCard extends StatelessWidget {
  final AsmaulHusnaModel name;

  const _NameCard({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${name.number}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Arabic name
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    name.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'Amiri',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Transliteration
            Text(
              name.tajik.transliteration,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            // Meaning
            Text(
              name.tajik.meaning,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
            ),
            if (name.found.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      name.found,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

