import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

class DuasMenuPage extends StatelessWidget {
  const DuasMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дуоҳо'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryCard(
            context: context,
            title: 'Раббано',
            description: 'Дуоҳои Қуръонӣ',
            icon: FlutterIslamicIcons.quran,
            onTap: () => context.push('/duas/rabbano'),
          ),
          const SizedBox(height: 16),
          _buildCategoryCard(
            context: context,
            title: 'Пайғамбарон',
            description: 'Дуоҳои пайғамбарони Аллоҳ',
            icon: FlutterIslamicIcons.mosque,
            onTap: () => context.push('/duas/prophets'),
          ),
          const SizedBox(height: 16),
          _buildCategoryCard(
            context: context,
            title: 'Дигар',
            description: 'Дуоҳои дигар',
            icon: Icons.image,
            onTap: () => context.push('/duas/other'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.1),
                theme.primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: theme.primaryColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

