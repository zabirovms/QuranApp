import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlight,
    this.style,
    this.highlightStyle,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final normalizedText = text.toLowerCase();
    final normalizedHighlight = highlight.toLowerCase();
    
    if (!normalizedText.contains(normalizedHighlight)) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final List<TextSpan> spans = [];
    int start = 0;
    
    while (start < text.length) {
      final index = normalizedText.indexOf(normalizedHighlight, start);
      
      if (index == -1) {
        // Add remaining text
        spans.add(TextSpan(
          text: text.substring(start),
          style: style,
        ));
        break;
      }
      
      // Add text before highlight
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }
      
      // Add highlighted text
      spans.add(TextSpan(
        text: text.substring(index, index + highlight.length),
        style: highlightStyle ?? 
               (style?.copyWith(
                 backgroundColor: Colors.yellow.withOpacity(0.3),
                 fontWeight: FontWeight.bold,
               ) ?? 
               const TextStyle(
                 backgroundColor: Colors.yellow,
                 fontWeight: FontWeight.bold,
               )),
      ));
      
      start = index + highlight.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
