import 'package:flutter/material.dart';

class ImagePermissionDialog extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ImagePermissionDialog({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.image,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Боргирии тасвирҳо',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Барои намоиши тасвирҳои дуо, барнома онҳоро боргирӣ ва захира мекунад. '
              'Ин амал метавонад мобилӣ интернет истифода кунад.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),

            // Info row for local caching
            _buildInfoRow(
              context,
              Icons.storage,
              'Захираи маҳаллӣ',
              'Тасвирҳо барои боздиди зуд ва офлайн захира мешаванд',
            ),

            const SizedBox(height: 12),

            // Info row for network usage
            _buildInfoRow(
              context,
              Icons.data_usage,
              'Истифодаи мобилӣ',
              'Мобилӣ интернет метавонад истифода шавад',
              isWarning: true,
            ),

            const SizedBox(height: 16),

            // Optional notice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Шумо метавонед ин танзимотро дар ҳар вақт тағйир диҳед',
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDecline,
          child: const Text(
            'Рад кардан',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Қабул кардан',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String description, {
    bool isWarning = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: isWarning ? Colors.orange[700] : Theme.of(context).primaryColor,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isWarning ? Colors.orange[700] : null,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
