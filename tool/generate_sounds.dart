// Generates the game's ORIGINAL sound effects as WAV files (no licensing).
// Run from the project root:   dart run tool/generate_sounds.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sampleRate = 44100;

void main() {
  final dir = Directory('assets/audio')..createSync(recursive: true);
  _write('${dir.path}/collect.wav', _collect());
  _write('${dir.path}/collision.wav', _collision());
  _write('${dir.path}/game_over.wav', _gameOver());
  _write('${dir.path}/button.wav', _button());
  _write('${dir.path}/milestone.wav', _milestone());
  stdout.writeln('Sounds written to ${dir.path}/');
}

/// A single tone gliding from [f0] to [f1] with a soft attack and decay.
List<double> _note(double f0, double f1, double seconds, double volume) {
  final n = (seconds * sampleRate).round();
  final out = List<double>.filled(n, 0);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final u = i / n;
    final f = f0 + (f1 - f0) * u;
    phase += 2 * math.pi * f / sampleRate;
    final attack = math.min(t / 0.006, 1.0);
    final decay = math.exp(-4.0 * u);
    final tail = math.min((n - i) / (0.012 * sampleRate), 1.0);
    out[i] = math.sin(phase) * attack * decay * tail * volume;
  }
  return out;
}

void _mix(List<double> into, List<double> add, double atSeconds) {
  final offset = (atSeconds * sampleRate).round();
  for (var i = 0; i < add.length && offset + i < into.length; i++) {
    into[offset + i] += add[i];
  }
}

List<double> _silence(double seconds) =>
    List<double>.filled((seconds * sampleRate).round(), 0);

List<double> _collect() {
  final b = _silence(0.26);
  _mix(b, _note(880, 900, 0.14, 0.45), 0);
  _mix(b, _note(1320, 1340, 0.18, 0.4), 0.07);
  return b;
}

List<double> _collision() {
  final b = _silence(0.42);
  _mix(b, _note(160, 45, 0.4, 0.7), 0);
  final rnd = math.Random(7);
  final noise = List<double>.generate(
    (0.25 * sampleRate).round(),
    (i) => (rnd.nextDouble() * 2 - 1) * math.exp(-9 * i / (0.25 * sampleRate)) * 0.45,
  );
  _mix(b, noise, 0);
  return b;
}

List<double> _gameOver() {
  final b = _silence(1.1);
  _mix(b, _note(440, 420, 0.32, 0.45), 0);
  _mix(b, _note(349, 330, 0.32, 0.45), 0.3);
  _mix(b, _note(262, 196, 0.6, 0.5), 0.6);
  return b;
}

List<double> _button() {
  final b = _silence(0.07);
  _mix(b, _note(620, 540, 0.06, 0.35), 0);
  return b;
}

List<double> _milestone() {
  final b = _silence(0.62);
  _mix(b, _note(523, 525, 0.2, 0.3), 0);
  _mix(b, _note(659, 661, 0.2, 0.3), 0.12);
  _mix(b, _note(784, 786, 0.35, 0.32), 0.24);
  return b;
}

void _write(String path, List<double> samples) {
  final bytes = ByteData(44 + samples.length * 2);
  void tag(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  bytes.setUint32(4, 36 + samples.length * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // mono
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  bytes.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = samples[i].clamp(-1.0, 1.0);
    bytes.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  File(path).writeAsBytesSync(bytes.buffer.asUint8List());
}
