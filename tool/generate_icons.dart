// Draws the app icon with pure Dart (no external art, no licensing issues).
// Run from the project root:   dart run tool/generate_icons.dart
//
// Output:
//   assets/icon/icon.png             1024x1024, opaque (iOS + legacy Android)
//   assets/icon/icon_foreground.png  1024x1024, transparent (Android adaptive)
//
// Concept: the white player dot, and your own recorded path (purple) leading
// back to the translucent Future Echo that is chasing it.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int size = 1024;

// Design tokens (same as the game).
const List<double> bg = [0x09, 0x0B, 0x12];
const List<double> bgCenter = [0x17, 0x1C, 0x33];
const List<double> echoColor = [0x8B, 0x7C, 0xFF];
const List<double> white = [0xF5, 0xF6, 0xFA];

void main() {
  final dir = Directory('assets/icon')..createSync(recursive: true);
  _save('${dir.path}/icon.png', _render(opaqueBackground: true, scale: 1.12));
  _save('${dir.path}/icon_foreground.png',
      _render(opaqueBackground: false, scale: 0.92));
  stdout.writeln('Icons written to ${dir.path}/');
}

/// Premultiplied RGBA accumulator.
class _Px {
  double r = 0, g = 0, b = 0, a = 0;

  void over(List<double> c, double alpha) {
    if (alpha <= 0) return;
    final k = 1 - alpha;
    r = c[0] * alpha + r * k;
    g = c[1] * alpha + g * k;
    b = c[2] * alpha + b * k;
    a = alpha + a * k;
  }
}

Uint8List _render({required bool opaqueBackground, required double scale}) {
  final n = size.toDouble();
  final c = n / 2;
  double sx(double v) => c + v * n * scale;

  // Motif geometry (relative to the canvas centre).
  final echo = [sx(-0.185), sx(-0.150)];
  final player = [sx(0.185), sx(0.165)];
  final dotR = 0.092 * n * scale;
  final halfW = 0.0105 * n * scale;

  // Cubic Bezier from echo -> player, an S-shaped recorded path.
  final p0 = echo;
  final p1 = [sx(0.020), sx(-0.255)];
  final p2 = [sx(-0.075), sx(0.215)];
  final p3 = player;
  const steps = 360;
  final curve = <List<double>>[];
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final u = 1 - t;
    curve.add([
      u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0],
      u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1],
    ]);
  }
  // Curve bounding box (+ glow margin) so we only test nearby pixels.
  final margin = halfW * 9;
  var minX = n, minY = n, maxX = 0.0, maxY = 0.0;
  for (final p in curve) {
    minX = math.min(minX, p[0]);
    minY = math.min(minY, p[1]);
    maxX = math.max(maxX, p[0]);
    maxY = math.max(maxY, p[1]);
  }

  final out = Uint8List(size * size * 4);
  final px = _Px();

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final fx = x + 0.5;
      final fy = y + 0.5;
      px
        ..r = 0
        ..g = 0
        ..b = 0
        ..a = 0;

      if (opaqueBackground) {
        // Soft radial lift in the centre, darker at the edges.
        final d = math.sqrt((fx - c) * (fx - c) + (fy - c) * (fy - c)) / (n * 0.72);
        final k = (1 - d).clamp(0.0, 1.0);
        final m = k * k;
        px.over([
          bg[0] + (bgCenter[0] - bg[0]) * m,
          bg[1] + (bgCenter[1] - bg[1]) * m,
          bg[2] + (bgCenter[2] - bg[2]) * m,
        ], 1);
      }

      // --- recorded path (brighter near the player = more recent) ---
      if (fx > minX - margin &&
          fx < maxX + margin &&
          fy > minY - margin &&
          fy < maxY + margin) {
        var best = double.infinity;
        var bestT = 0.0;
        for (var i = 0; i < curve.length; i++) {
          final dx = fx - curve[i][0];
          final dy = fy - curve[i][1];
          final d2 = dx * dx + dy * dy;
          if (d2 < best) {
            best = d2;
            bestT = i / steps;
          }
        }
        final d = math.sqrt(best);
        // Hide the line under the two dots so only the path BETWEEN them shows.
        final dE = math.sqrt((fx - echo[0]) * (fx - echo[0]) + (fy - echo[1]) * (fy - echo[1]));
        final dP = math.sqrt((fx - player[0]) * (fx - player[0]) + (fy - player[1]) * (fy - player[1]));
        final hide = math.min(
          ((dE - dotR * 0.9) / (dotR * 0.35)).clamp(0.0, 1.0),
          ((dP - dotR * 0.9) / (dotR * 0.35)).clamp(0.0, 1.0),
        );
        final recency = (0.12 + 0.6 * bestT) * hide;
        final glow = math.exp(-math.pow(d / (halfW * 3.6), 2)) * 0.22 * recency;
        px.over(echoColor, glow);
        final cov = (0.5 - (d - halfW)).clamp(0.0, 1.0);
        px.over(echoColor, cov * recency);
      }

      // --- Future Echo (translucent, glowing) ---
      {
        final d = math.sqrt((fx - echo[0]) * (fx - echo[0]) + (fy - echo[1]) * (fy - echo[1]));
        if (d > dotR) {
          px.over(echoColor, 0.42 * math.exp(-(d - dotR) / (dotR * 0.75)));
        }
        px.over(echoColor, (0.5 - (d - dotR)).clamp(0.0, 1.0) * 0.72);
      }

      // --- Player (white, glowing) ---
      {
        final d = math.sqrt((fx - player[0]) * (fx - player[0]) + (fy - player[1]) * (fy - player[1]));
        if (d > dotR) {
          px.over(white, 0.5 * math.exp(-(d - dotR) / (dotR * 0.7)));
        }
        px.over(white, (0.5 - (d - dotR)).clamp(0.0, 1.0));
      }

      // Un-premultiply to straight alpha for PNG.
      final i = (y * size + x) * 4;
      final a = px.a;
      if (a <= 0.0001) {
        out[i] = out[i + 1] = out[i + 2] = out[i + 3] = 0;
      } else {
        out[i] = (px.r / a).round().clamp(0, 255);
        out[i + 1] = (px.g / a).round().clamp(0, 255);
        out[i + 2] = (px.b / a).round().clamp(0, 255);
        out[i + 3] = (a * 255).round().clamp(0, 255);
      }
    }
  }
  return out;
}

// ---------------------------------------------------------------- PNG ----

void _save(String path, Uint8List rgba) =>
    File(path).writeAsBytesSync(_encodePng(size, size, rgba));

Uint8List _encodePng(int w, int h, Uint8List rgba) {
  final raw = BytesBuilder();
  for (var y = 0; y < h; y++) {
    raw.addByte(0); // filter: none
    raw.add(Uint8List.sublistView(rgba, y * w * 4, (y + 1) * w * 4));
  }
  final compressed = ZLibCodec(level: 6).encode(raw.toBytes());

  final out = BytesBuilder();
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  final ihdr = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 6) // RGBA
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  _chunk(out, 'IHDR', ihdr.buffer.asUint8List());
  _chunk(out, 'IDAT', Uint8List.fromList(compressed));
  _chunk(out, 'IEND', Uint8List(0));
  return out.toBytes();
}

void _chunk(BytesBuilder out, String type, Uint8List data) {
  final len = ByteData(4)..setUint32(0, data.length);
  out.add(len.buffer.asUint8List());
  final body = BytesBuilder()
    ..add(type.codeUnits)
    ..add(data);
  final bytes = body.toBytes();
  out.add(bytes);
  final crc = ByteData(4)..setUint32(0, _crc32(bytes));
  out.add(crc.buffer.asUint8List());
}

final List<int> _crcTable = () {
  final t = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    t[n] = c;
  }
  return t;
}();

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
