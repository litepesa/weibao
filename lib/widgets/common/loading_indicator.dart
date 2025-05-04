import 'package:flutter/material.dart';
import 'package:weibao/config/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  final double size;
  
  const LoadingIndicator({
    super.key,
    this.message = 'Loading...',
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 3,
          ),
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}