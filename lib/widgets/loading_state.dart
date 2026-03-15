import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  final String message;
  const LoadingState({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.message = 'Something went wrong.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}