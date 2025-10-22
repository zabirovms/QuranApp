import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isShimmer;
  final LoadingType type;
  final Color? baseColor;
  final Color? highlightColor;

  const LoadingWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.isShimmer = true,
    this.type = LoadingType.rectangle,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isShimmer) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Enhanced color scheme
    final base = widget.baseColor ?? 
        (isDark ? Colors.grey[800]!.withValues(alpha: 0.3) : Colors.grey[200]!.withValues(alpha: 0.3));
    final highlight = widget.highlightColor ?? 
        (isDark ? Colors.grey[600]!.withValues(alpha: 0.6) : Colors.grey[50]!.withValues(alpha: 0.8));
    
    // Gradient background for better visual appeal
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.grey[850]!.withValues(alpha: 0.4),
              Colors.grey[800]!.withValues(alpha: 0.2),
              Colors.grey[850]!.withValues(alpha: 0.4),
            ]
          : [
              Colors.grey[100]!.withValues(alpha: 0.6),
              Colors.grey[50]!.withValues(alpha: 0.3),
              Colors.grey[100]!.withValues(alpha: 0.6),
            ],
    );

    Widget content = _buildContent(theme, gradient, base, highlight);

    if (widget.isShimmer) {
      return Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        period: const Duration(milliseconds: 1000),
        direction: ShimmerDirection.ltr,
        child: content,
      );
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme, LinearGradient gradient, Color base, Color highlight) {
    final isDark = theme.brightness == Brightness.dark;
    
    switch (widget.type) {
      case LoadingType.rectangle:
        return Container(
          width: widget.width,
          height: widget.height ?? 20,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            border: Border.all(
              color: isDark 
                  ? Colors.grey[700]!.withValues(alpha: 0.3)
                  : Colors.grey[300]!.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      
      case LoadingType.circle:
        return Container(
          width: widget.width ?? widget.height ?? 40,
          height: widget.height ?? widget.width ?? 40,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      
      case LoadingType.card:
        return Container(
          width: widget.width,
          height: widget.height ?? 120,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  width: 200,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      
      case LoadingType.text:
        return Container(
          width: widget.width,
          height: widget.height ?? 16,
          decoration: BoxDecoration(
            color: base,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          ),
        );
    }
  }
}

enum LoadingType {
  rectangle,
  circle,
  card,
  text,
}

class LoadingListWidget extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? padding;
  final LoadingType itemType;
  final bool isShimmer;

  const LoadingListWidget({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding,
    this.itemType = LoadingType.rectangle,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: LoadingWidget(
            height: itemHeight,
            type: itemType,
            isShimmer: isShimmer,
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
  final LoadingType itemType;
  final bool isShimmer;

  const LoadingGridWidget({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.5,
    this.padding,
    this.itemType = LoadingType.card,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LoadingWidget(
          type: itemType,
          isShimmer: isShimmer,
          borderRadius: BorderRadius.circular(12),
        );
      },
    );
  }
}

// Specialized loading widgets for common use cases
class LoadingCardWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final bool isShimmer;

  const LoadingCardWidget({
    super.key,
    this.width,
    this.height,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      width: width,
      height: height ?? 120,
      type: LoadingType.card,
      isShimmer: isShimmer,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

class LoadingTextWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final int lines;
  final bool isShimmer;

  const LoadingTextWidget({
    super.key,
    this.width,
    this.height,
    this.lines = 3,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? 8 : 0),
          child: LoadingWidget(
            width: index == lines - 1 ? (width ?? 200) * 0.7 : width,
            height: height ?? 16,
            type: LoadingType.text,
            isShimmer: isShimmer,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class LoadingCircularWidget extends StatelessWidget {
  final double? size;
  final bool isShimmer;

  const LoadingCircularWidget({
    super.key,
    this.size,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      width: size ?? 40,
      height: size ?? 40,
      type: LoadingType.circle,
      isShimmer: isShimmer,
    );
  }
}
