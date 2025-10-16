import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isShimmer;

  const LoadingWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlight = theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!;
    final bg = theme.colorScheme.surfaceContainerHighest.withOpacity(0.6);
    if (isShimmer) {
      return Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Container(
          width: width,
          height: height ?? 20,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: borderRadius ?? BorderRadius.circular(4),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height ?? 20,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class LoadingListWidget extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? padding;

  const LoadingListWidget({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LoadingWidget(
            height: itemHeight,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

class LoadingGridWidget extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsets? padding;

  const LoadingGridWidget({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LoadingWidget(
          borderRadius: BorderRadius.circular(12),
        );
      },
    );
  }
}
