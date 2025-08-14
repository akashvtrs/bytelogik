import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../providers/providers.dart';

class CounterScreen extends ConsumerWidget {
  final User user;
  const CounterScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider(user.id));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Counter App'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text('Welcome back!', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(user.email,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Counter Display
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Text('Counter', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Text('$counter',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            )),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CounterButton(
                    icon: Icons.add,
                    label: 'Increment',
                    color: Colors.green,
                    onPressed: () => ref.read(counterProvider(user.id).notifier).increment(),
                  ),
                  _CounterButton(
                    icon: Icons.remove,
                    label: 'Decrement',
                    color: Colors.orange,
                    onPressed: () => ref.read(counterProvider(user.id).notifier).decrement(),
                  ),
                  _CounterButton(
                    icon: Icons.refresh,
                    label: 'Reset',
                    color: Colors.red,
                    onPressed: () => ref.read(counterProvider(user.id).notifier).reset(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  const _CounterButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
