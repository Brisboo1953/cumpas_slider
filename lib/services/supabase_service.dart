import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio centralizado para gestionar todas las interacciones con Supabase.
/// 
/// Encapsula autenticación, consultas y operaciones CRUD en la tabla 'players'.
class SupabaseService {
  final SupabaseClient _client;
  bool _triedEnvAuth = false; // evita múltiples intentos con credenciales .env inválidas

  /// Constructor. Recibe el cliente de Supabase (por defecto usa Supabase.instance.client).
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Obtiene el cliente de Supabase (útil si necesitas acceso directo en casos especiales).
  SupabaseClient get client => _client;

  /// Obtiene el usuario actualmente autenticado.
  User? get currentUser => _client.auth.currentUser;

  /// Obtiene la sesión actual.
  Session? get currentSession => _client.auth.currentSession;

  /// Stream que emite cambios en el estado de autenticación.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // ============================================================================
  // AUTENTICACIÓN
  // ============================================================================

  /// Inicia sesión con email y contraseña.
  /// 
  /// Retorna `true` si la autenticación fue exitosa, `false` en caso contrario.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        debugPrint('❌ Error signing in: No session returned');
        return false;
      } else {
        debugPrint('✅ User signed in: ${response.user?.email}');
        return true;
      }
    } catch (error) {
      debugPrint('❌ Error inesperado al hacer sign in: $error');
      return false;
    }
  }

  /// Intenta autenticar con las credenciales en .env UNA sola vez.
  /// Retorna true si al final hay una sesión válida.
  Future<bool> _ensureSessionFromEnvOnce() async {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;
    if (session != null && user != null) return true;
    if (_triedEnvAuth) return false;
    _triedEnvAuth = true;
    final email = dotenv.env['AUTH_EMAIL'];
    final password = dotenv.env['AUTH_PASSWORD'];
    if (email == null || password == null) {
      debugPrint('⚠️ AUTH_EMAIL / AUTH_PASSWORD not set in .env; skipping auth attempt.');
      return false;
    }
    debugPrint('🔐 Attempting environment sign-in for Supabase (one-time attempt).');
    final ok = await signIn(email: email, password: password);
    if (!ok) debugPrint('⚠️ Environment sign-in failed (invalid credentials).');
    return ok;
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      debugPrint('✅ Usuario deslogueado.');
    } catch (error) {
      debugPrint('❌ Error al hacer sign out: $error');
    }
  }

  // ============================================================================
  // OPERACIONES EN LA TABLA 'players'
  // ============================================================================

  /// Inserta un nuevo jugador en la tabla 'players'.
  /// 
  /// Si no hay sesión activa, intenta hacer sign-in primero usando credenciales del .env.
  /// 
  /// Parámetros:
  /// - [playerName]: Nombre del jugador.
  /// - [points]: Puntos iniciales del jugador.
  /// - [userId]: ID del usuario propietario (opcional, por defecto usa un ID fijo).
  Future<void> insertPlayer({
    required String playerName,
    required int points,
    String? userId,
  }) async {
    // Asegura sesión (intenta signin con .env si no hay sesión)
    var session = _client.auth.currentSession;
    var user = _client.auth.currentUser;
    if (session == null || user == null) {
      final ok = await _ensureSessionFromEnvOnce();
      if (!ok) {
        debugPrint('⚠️ No hay sesión activa y la autenticación desde .env no se pudo completar. No se insertará jugador.');
        return;
      }
      session = _client.auth.currentSession;
      user = _client.auth.currentUser;
    }

    try {
      final uid = user?.id ?? userId;
      final newPlayer = {
        'player_name': playerName,
        'points': points,
        if (uid != null) 'user_id': uid,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('players').insert(newPlayer);
      debugPrint('✅ Jugador insertado exitosamente: $playerName (user_id: $uid)');
    } on PostgrestException catch (error) {
      debugPrint('❌ Error al insertar jugador: ${error.message}');
    } catch (error) {
      debugPrint('❌ Error inesperado al insertar: $error');
    }
  }

  /// Actualiza los puntos de un jugador existente en la tabla 'players'.
  /// 
  /// Filtra por el nombre del jugador.
  /// 
  /// Parámetros:
  /// - [playerName]: Nombre del jugador a actualizar.
  /// - [points]: Nuevos puntos del jugador.
  Future<void> updatePlayer({
    required String playerName,
    required int points,
  }) async {
    try {
      final updatedData = {
        'player_name': playerName,
        'points': points,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('players')
          .update(updatedData)
          .eq('player_name', playerName);

      debugPrint('✅ Jugador con nombre $playerName actualizado exitosamente.');
    } on PostgrestException catch (error) {
      debugPrint('❌ Error al actualizar jugador: ${error.message}');
    } catch (error) {
      debugPrint('❌ Error inesperado al actualizar: $error');
    }
  }

  /// Verifica si un jugador existe. Si existe, lo actualiza; si no, lo inserta (UPSERT).
  /// 
  /// Parámetros:
  /// - [playerName]: Nombre del jugador.
  /// - [score]: Puntos a asignar o actualizar.
  Future<void> checkAndUpsertPlayer({
    required String playerName,
    required int score,
  }) async {
    try {
      // Aseguramos sesión desde .env si hace falta (intento una sola vez)
      var user = _client.auth.currentUser;
      if (user == null) {
        await _ensureSessionFromEnvOnce();
        user = _client.auth.currentUser;
      }
      final uid = user?.id;

      final row = {
        'player_name': playerName,
        'points': score,
        if (uid != null) 'user_id': uid,
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        // Preferimos usar el método upsert nativo si está disponible en el cliente
        await _client.from('players').upsert(row);
        debugPrint('✅ Upsert realizado para $playerName -> $score');
        return;
      } catch (e) {
        // Si no está disponible o falla, hacemos fallback a select+update/insert
        debugPrint('⚠️ Upsert nativo falló o no disponible, usando fallback: $e');
      }

      // FALLBACK: comprobar existencia y hacer update o insert
      final response = await _client.from('players').select('id, player_name, points').eq('player_name', playerName).limit(1);
      if (response.isNotEmpty) {
        debugPrint('Jugador $playerName encontrado en fallback. Actualizando...');
        await updatePlayer(playerName: playerName, points: score);
      } else {
        debugPrint('Jugador $playerName no encontrado en fallback. Insertando...');
        await insertPlayer(playerName: playerName, points: score, userId: uid);
      }
    } on PostgrestException catch (error) {
      debugPrint('❌ Error de Supabase en checkAndUpsertPlayer: ${error.message}');
    } catch (error) {
      debugPrint('❌ Error inesperado en checkAndUpsertPlayer: $error');
    }
  }

  /// Recupera los puntos de un jugador desde la tabla 'players'.
  /// 
  /// Retorna los puntos si el jugador existe, o `null` si no se encuentra.
  /// 
  /// Parámetros:
  /// - [playerName]: Nombre del jugador a buscar.
  Future<int?> retrievePoints({required String playerName}) async {
    try {
      final response = await _client
          .from('players')
          .select('points')
          .eq('player_name', playerName)
          .limit(1);

      if (response.isNotEmpty) {
        final playerData = response.first;
        final points = playerData['points'] as int;
        debugPrint('✅ Puntos recuperados para $playerName: $points');
        return points;
      } else {
        debugPrint('⚠️ Jugador $playerName no encontrado.');
        return null;
      }
    } catch (error) {
      debugPrint('❌ Error inesperado al recuperar puntos: $error');
      return null;
    }
  }

  /// Inserta una puntuación simple en la tabla 'players' usando campos comunes.
  /// Inserta name (player_name) y score (points).
  Future<void> insertScore({required String name, required int score}) async {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;

    if (session == null || user == null) {
      final ok = await _ensureSessionFromEnvOnce();
      if (!ok) {
        debugPrint('⚠️ No hay sesión activa y la autenticación desde .env no se pudo completar. Guardando puntuación localmente.');
        await _queuePendingScore(name: name, score: score);
        return;
      }
    }

    try {
      final uid = _client.auth.currentUser?.id;
      final row = {
        'player_name': name,
        'points': score,
        if (uid != null) 'user_id': uid,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Intentamos usar upsert para evitar duplicados si existe constraint único
      try {
        await _client.from('players').upsert(row);
        debugPrint('✅ Score upserted: $name -> $score (user_id: $uid)');
      } catch (e) {
        // Fallback simple a insert
        try {
          await _client.from('players').insert(row);
          debugPrint('✅ Score insertado (fallback): $name -> $score (user_id: $uid)');
        } catch (err2) {
          debugPrint('❌ No se pudo insertar score (fallback también falló): $err2 — encolando localmente');
          await _queuePendingScore(name: name, score: score);
        }
      }
    } catch (e) {
      debugPrint('❌ Error insertando score: $e — encolando localmente');
      await _queuePendingScore(name: name, score: score);
    }
  }

  // --------------------- Pending local queue ----------------------
  Future<void> _queuePendingScore({required String name, required int score}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'pending_scores';
      final existing = prefs.getStringList(key) ?? [];
      final item = jsonEncode({'name': name, 'score': score, 'ts': DateTime.now().toIso8601String()});
      existing.add(item);
      await prefs.setStringList(key, existing);
      debugPrint('✅ Score encolado localmente: $name -> $score');
    } catch (e) {
      debugPrint('❌ Error guardando score localmente: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingScores() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'pending_scores';
    final list = prefs.getStringList(key) ?? [];
    return list.map((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return m;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((m) => m.isNotEmpty).toList();
  }

  /// Intenta subir las puntuaciones pendientes. Si una se sube correctamente
  /// la elimina de la cola. Retorna el número de filas sincronizadas.
  Future<int> syncPendingScores() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'pending_scores';
    final list = prefs.getStringList(key) ?? [];
    if (list.isEmpty) return 0;
    int success = 0;
    final remaining = <String>[];
    for (final s in list) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final name = map['name'] as String?;
        final score = (map['score'] as num?)?.toInt();
        if (name == null || score == null) {
          continue;
        }
        try {
          // Note: insertScore will re-enqueue on failure, so call low-level upsert instead
          await _client.from('players').upsert({'player_name': name, 'points': score, 'updated_at': DateTime.now().toIso8601String()});
          success++;
        } catch (e) {
          remaining.add(s);
        }
      } catch (_) {
        // ignore malformed entries
      }
    }
    await prefs.setStringList(key, remaining);
    debugPrint('🔁 Sincronización completada. Éxitos: $success, Pendientes: ${remaining.length}');
    return success;
  }

  /// Obtiene las puntuaciones ordenadas descendentes (mayor a menor) usando la
  /// instancia privada `_client`.
  Future<List<Map<String, dynamic>>> getTopScores({int limit = 50}) async {
    try {
      final resp = await _client.from('players').select('player_name, points').order('points', ascending: false).limit(limit) as List;
      final List<Map<String, dynamic>> list = [];
      for (final row in resp) {
        list.add({'name': row['player_name'], 'score': row['points']});
      }
      return list;
    } catch (e) {
      debugPrint('❌ Error fetching top scores: $e');
      return [];
    }
  }
}
