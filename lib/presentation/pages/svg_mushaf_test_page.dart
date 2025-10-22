import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/svg_mushaf_provider.dart';

class SvgMushafTestPage extends ConsumerWidget {
  const SvgMushafTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG Mushaf Test'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              print('Testing SVG service...');
              try {
                final repository = ref.read(svgMushafRepositoryProvider);
                final page = await repository.getPage(1);
                print('Page loaded: ${page.pageNumber}');
                print('Is loaded: ${page.isLoaded}');
                print('SVG content length: ${page.svgContent.length}');
                print('First 100 chars: ${page.svgContent.substring(0, page.svgContent.length > 100 ? 100 : page.svgContent.length)}');
              } catch (e) {
                print('Error: $e');
              }
            },
            child: const Text('Test Load Page 1'),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: MushafPageView(pageNumber: 1),
          ),
        ],
      ),
    );
  }
}
