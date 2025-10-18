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
          const Text('Иҷозаи боргирии тасвирҳо'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Барои намоиши беҳтарини тасвирҳои дуо, барнома тасвирҳоро аз сервер боргирӣ мекунад:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          _buildInfoItem(
            context,
            Icons.cloud_download,
            'Боргирии тасвирҳо',
            'Тасвирҳо аз сервер Google Cloud Storage боргирӣ мешаванд',
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoItem(
            context,
            Icons.storage,
            'Захираи маҳаллӣ',
            'Тасвирҳо дар дастгоҳ захира мешаванд барои боздиди зуд ва офлайн',
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoItem(
            context,
            Icons.data_usage,
            'Истифодаи мобилӣ',
            'Ин амал метавонад мобилӣ интернет истифода кунад',
            isWarning: true,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
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
                    'Шумо метавонед ин танзимотро дар ҳар вақт дар тарҳҳо тағйир диҳед',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildInfoItem(
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
        const SizedBox(width: 12),
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
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
