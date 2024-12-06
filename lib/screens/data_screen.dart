import 'package:flutter/material.dart';
import '../widgets/app_layout.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 2,
      child: Column(
        children: [
          AppBar(
            title: const Text('Data Management'),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _DataCard(
                  title: 'Items',
                  icon: Icons.inventory,
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/items'),
                ),
                _DataCard(
                  title: 'Warehouses',
                  icon: Icons.warehouse,
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/warehouses'),
                ),
                _DataCard(
                  title: 'Item Groups',
                  icon: Icons.category,
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(context, '/item-groups'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DataCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
