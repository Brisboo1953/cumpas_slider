import 'package:audioplayers/audioplayers.dart';

class MusicService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playMenu() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Try playing as an asset first (recommended)
      try {
        await _player.play(AssetSource('menu_music.mp3'));
        return;
      } catch (e) {
        // If asset playback fails on web (format/mime issues), try a URL fallback
        // We'll fall through to UrlSource below.
        print('AudioPlayers: AssetSource failed, trying UrlSource fallback: $e');
      }

      // Fallback: try resolving the asset via a URL (useful for web servers)
      try {
        final url = Uri.base.resolve('assets/menu_music.mp3').toString();
        await _player.play(UrlSource(url));
        return;
      } catch (err) {
        print('AudioPlayers: UrlSource fallback failed for mp3: $err');
      }

      // Try an OGG variant if available (some browsers prefer/require different encodings)
      try {
        final urlOgg = Uri.base.resolve('assets/menu_music.ogg').toString();
        await _player.play(UrlSource(urlOgg));
        return;
      } catch (err2) {
        print('AudioPlayers: UrlSource fallback failed for ogg: $err2');
        rethrow;
      }
    } catch (e) {
      // ignore errors silently for now
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      // ignore
    }
  }
}
