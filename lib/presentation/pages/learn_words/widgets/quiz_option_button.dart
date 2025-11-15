import 'package:flutter/material.dart';

class QuizOptionButton extends StatelessWidget {
  final String option;
  final bool isCorrect;
  final bool isSelected;
  final bool alreadyAnswered;
  final VoidCallback? onPressed;
  final Widget? trailingIcon;

  const QuizOptionButton({
    super.key,
    required this.option,
    required this.isCorrect,
    required this.isSelected,
    required this.alreadyAnswered,
    this.onPressed,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? textColor;

    if (alreadyAnswered) {
      if (isCorrect) {
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
      } else if (isSelected) {
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
      } else {
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          elevation: alreadyAnswered ? 0 : 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                option,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (trailingIcon != null) trailingIcon!,
          ],
        ),
      ),
    );
  }
}
