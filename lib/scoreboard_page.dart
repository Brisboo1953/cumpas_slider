import 'package:flutter/material.dart';
import 'services/supabase_service.dart';

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  late Future<List<Map<String, dynamic>>> _scoresFuture;
  int _pendingCount = 0;

  Future<void> _loadPendingCount() async {
    final pending = await SupabaseService().getPendingScores();
    setState(() {
      _pendingCount = pending.length;
    });
  }

  @override
  void initState() {
    super.initState();
    _scoresFuture = SupabaseService().getTopScores(limit: 50);
    _loadPendingCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntuaciones'),
        actions: [
          if (_pendingCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Center(child: Text('Pendientes: $_pendingCount')),
            ),
          IconButton(
            tooltip: 'Sincronizar pendientes',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final synced = await SupabaseService().syncPendingScores();
              await _loadPendingCount();
              setState(() {
                _scoresFuture = SupabaseService().getTopScores(limit: 50);
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sincronizados: $synced')));
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _scoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar puntuaciones: ${snapshot.error}'));
          }
          final scores = snapshot.data ?? [];
          if (scores.isEmpty) {
            return const Center(child: Text('No hay puntuaciones aún.'));
          }
          return ListView.separated(
            itemCount: scores.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = scores[index];
              final name = row['name'] ?? '---';
              final score = row['score'] ?? 0;
              return ListTile(
                leading: Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                title: Text(name),
                trailing: Text(score.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }
}
