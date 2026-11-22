import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../data/repositories/search_repository.dart';
import '../models/enums.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final Set<SearchFilter> _filters = {};
  List<SearchResult> _results = [];

  Future<void> _search(String query) async {
    if (!Validators.isValidQuery(query)) {
      setState(() => _results = []);
      return;
    }

    final repo = context.read<SearchRepository>();
    final results = await repo.search(query, 'local-user', _filters);

    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Поиск задач, событий и привычек',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: SearchFilter.values.map((filter) {
              final selected = _filters.contains(filter);

              return FilterChip(
                label: Text(switch (filter) {
                  SearchFilter.tasks => 'Только задачи',
                  SearchFilter.events => 'Только события',
                  SearchFilter.habits => 'Только привычки',
                  SearchFilter.completed => 'Выполненные',
                  SearchFilter.overdue => 'Просроченные',
                }),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    value ? _filters.add(filter) : _filters.remove(filter);
                  });
                  _search(_controller.text);
                },
              );
            }).toList(),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text('По вашему запросу ничего не найдено'),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];

                      return ListTile(
                        leading: Icon(
                          switch (result.entityType) {
                            EntityType.task => Icons.check_circle_outline,
                            EntityType.event => Icons.event_outlined,
                            EntityType.habit => Icons.repeat_outlined,
                          },
                        ),
                        title: Text(result.title),
                        subtitle: Text(result.matchedFragment),
                        trailing: Text(result.entityType.label),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}