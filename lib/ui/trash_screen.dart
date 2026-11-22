import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/services/trash_service.dart';
import '../models/enums.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<TrashService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: FutureBuilder<List<TrashItem>>(
        future: service.getItems('local-user'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return const Center(child: Text('Корзина пуста.'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final canRestore = item.canRestore(DateTime.now());

              return ListTile(
                leading: Icon(
                  switch (item.type) {
                    EntityType.task => Icons.check_circle_outline,
                    EntityType.event => Icons.event_outlined,
                    EntityType.habit => Icons.repeat_outlined,
                  },
                ),
                title: Text(item.title),
                subtitle: Text(
                  'Удалено: ${item.deletedAt.toIso8601String().substring(0, 10)}\n'
                  'Осталось: ${item.timeLeft(DateTime.now()).inDays} дн.',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: canRestore
                      ? () async {
                          await service.restore(item.id, item.type);
                        }
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}