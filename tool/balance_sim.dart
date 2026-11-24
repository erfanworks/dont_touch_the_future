// Balance simulator: plays hundreds of runs with look-ahead bots and prints
// survival / score statistics, so difficulty changes can be judged with data.
//
//   dart run tool/balance_sim.dart            (24 runs per bot, 360 s max)
//   dart run tool/balance_sim.dart 60 480     (60 runs per bot, 480 s max)
//
// IMPORTANT: bots are a relative signal, not a replacement for real players.
// A "pro" bot has perfect look-ahead; a "casual" bot is slower and blunders.
import 'dart:math' as math;

import 'package:dont_touch_the_future/core/constants/game_constants.dart';
import 'package:dont_touch_the_future/features/gameplay/game/game_session.dart';
import 'package:dont_touch_the_future/features/gameplay/game/systems/movement_history.dart';

class BotProfile {
  const BotProfile(this.name,
      {required this.horizon, required this.noise, required this.reaction});
  final String name;
  final double horizon; // seconds the bot looks ahead
  final double noise; // chance of a blunder per decision
  final double reaction; // seconds between decisions
}

const profiles = [
  BotProfile('pro   ', horizon: 0.7, noise: 0.0, reaction: 0.05),
  BotProfile('good  ', horizon: 0.5, noise: 0.05, reaction: 0.10),
  BotProfile('casual', horizon: 0.4, noise: 0.12, reaction: 0.16),
];

const int dirs = 16;

class Bot {
  Bot(this.s, this.p, this.rnd);
  final GameSession s;
  final BotProfile p;
  final math.Random rnd;
  final MutablePoint _tmp = MutablePoint();
  double _next = 0;
  int _dir = -1;

  void tick() {
    if (s.gameTime < _next) return;
    _next = s.gameTime + p.reaction;
    var best = -1;
    var bestCost = double.infinity;
    for (var k = -1; k < dirs; k++) {
      var c = _cost(k);
      if (k == _dir) c -= 0.5; // inertia: avoids jitter
      if (c < bestCost) {
        bestCost = c;
        best = k;
      }
    }
    if (rnd.nextDouble() < p.noise) best = rnd.nextInt(dirs);
    _dir = best;
    s.endDrag();
    if (best >= 0) {
      final a = best * 2 * math.pi / dirs;
      s.beginDrag();
      s.dragBy(math.cos(a) * 80, math.sin(a) * 80);
    }
  }

  double _danger(double gap) {
    if (gap < 0) return 5000;
    final reach = 70 * s.unit;
    if (gap > reach) return 0;
    final f = 1 - gap / reach;
    return 400 * f * f;
  }

  double _cost(int k) {
    final v = s.player.speed;
    const stepT = 0.1;
    final steps = (p.horizon / stepT).round();
    final hit = s.playerRadius * GameConstants.hazardHitboxFactor;
    final a = k < 0 ? 0.0 : k * 2 * math.pi / dirs;
    final dx = k < 0 ? 0.0 : math.cos(a);
    final dy = k < 0 ? 0.0 : math.sin(a);
    var x = s.player.x;
    var y = s.player.y;
    var cost = 0.0;

    for (var j = 1; j <= steps; j++) {
      final tau = j * stepT;
      x = (x + dx * v * stepT).clamp(s.player.minX, s.player.maxX);
      y = (y + dy * v * stepT).clamp(s.player.minY, s.player.maxY);

      for (final o in s.obstacles) {
        if (!(o.isArmed || o.age + tau >= GameConstants.obstacleArmSeconds)) {
          continue;
        }
        var ox = o.x;
        var oy = o.y;
        if (o.isMoving) {
          final moving = tau - math.max(0.0, GameConstants.obstacleArmSeconds - o.age);
          if (moving > 0) {
            ox = (o.x + o.vx * moving).clamp(s.arenaLeft, s.arenaRight);
            oy = (o.y + o.vy * moving).clamp(s.arenaTop, s.arenaBottom);
          }
        }
        final d = math.sqrt((x - ox) * (x - ox) + (y - oy) * (y - oy));
        cost += _danger(d - hit - o.radius);
      }

      final t1 = s.gameTime + tau - GameConstants.echoDelaySeconds;
      if (t1 >= GameConstants.echoSpawnGraceSeconds * 0.5) {
        s.history.sampleAt(t1, _tmp);
        final d = math.sqrt((x - _tmp.x) * (x - _tmp.x) + (y - _tmp.y) * (y - _tmp.y));
        cost += _danger(d - hit - s.echoRadius);
      }
      if (s.gameTime + tau >= GameConstants.secondEchoStartSeconds) {
        final t2 = s.gameTime + tau - GameConstants.secondEchoDelaySeconds;
        s.history.sampleAt(t2, _tmp);
        final d = math.sqrt((x - _tmp.x) * (x - _tmp.x) + (y - _tmp.y) * (y - _tmp.y));
        cost += _danger(d - hit - s.echoRadius);
      }
    }

    // Stay away from walls (corners are death traps).
    final wall = math.min(
      math.min(x - s.arenaLeft, s.arenaRight - x),
      math.min(y - s.arenaTop, s.arenaBottom - y),
    );
    final safe = 45 * s.unit;
    if (wall < safe) cost += (safe - wall) * 0.6;

    // Gentle pull toward the nearest shard.
    var nearest = double.infinity;
    for (final sh in s.shards) {
      final d = math.sqrt((x - sh.x) * (x - sh.x) + (y - sh.y) * (y - sh.y));
      if (d < nearest) nearest = d;
    }
    if (nearest.isFinite) cost += nearest * 0.02;
    return cost;
  }
}

class RunResult {
  RunResult(this.seconds, this.score, this.shards, this.grazes, this.chain,
      this.cause, this.reachedCap);
  final double seconds;
  final int score;
  final int shards;
  final int grazes;
  final int chain;
  final DeathCause? cause;
  final bool reachedCap;
}

RunResult play(BotProfile p, int seed, double maxSeconds) {
  final s = GameSession(random: math.Random(seed))..configureArena(390, 844, insetTop: 47, insetBottom: 34);
  final bot = Bot(s, p, math.Random(seed * 7919 + 13));
  s.beginDrag();
  const frame = 1 / 60;
  while (s.isPlaying && s.gameTime < maxSeconds) {
    bot.tick();
    s.update(frame);
  }
  return RunResult(
    s.gameTime,
    s.score,
    s.scoring.shardsCollected,
    s.scoring.grazeCount,
    s.scoring.bestChain,
    s.deathCause,
    s.isPlaying,
  );
}

double pct(List<double> sorted, double q) =>
    sorted[((sorted.length - 1) * q).round()];

void main(List<String> args) {
  final runs = args.isNotEmpty ? int.parse(args[0]) : 24;
  final maxSeconds = args.length > 1 ? double.parse(args[1]) : 360.0;

  print('Balance simulation: $runs runs per bot, max ${maxSeconds.toStringAsFixed(0)} s\n');
  print('bot     | median  p25   p75   | >=60s  >=120s >=180s | echo%  obst% cap% | score  shards grazes chain');
  print('--------+------------------------+----------------------+-----------------+--------------------------');
  for (final p in profiles) {
    final res = [for (var i = 0; i < runs; i++) play(p, 1000 + i, maxSeconds)];
    final secs = res.map((r) => r.seconds).toList()..sort();
    double share(bool Function(RunResult) f) => res.where(f).length * 100 / runs;
    double avg(num Function(RunResult) f) => res.map(f).reduce((a, b) => a + b) / runs;
    print('${p.name} | ${pct(secs, .5).toStringAsFixed(0).padLeft(5)}s ${pct(secs, .25).toStringAsFixed(0).padLeft(4)}s ${pct(secs, .75).toStringAsFixed(0).padLeft(4)}s | '
        '${share((r) => r.seconds >= 60).toStringAsFixed(0).padLeft(4)}%  ${share((r) => r.seconds >= 120).toStringAsFixed(0).padLeft(4)}%  ${share((r) => r.seconds >= 180).toStringAsFixed(0).padLeft(4)}% | '
        '${share((r) => r.cause == DeathCause.echo).toStringAsFixed(0).padLeft(4)}%  ${share((r) => r.cause == DeathCause.obstacle).toStringAsFixed(0).padLeft(4)}%  ${share((r) => r.reachedCap).toStringAsFixed(0).padLeft(3)}% | '
        '${avg((r) => r.score).toStringAsFixed(0).padLeft(6)} ${avg((r) => r.shards).toStringAsFixed(1).padLeft(6)} ${avg((r) => r.grazes).toStringAsFixed(1).padLeft(6)} ${avg((r) => r.chain).toStringAsFixed(1).padLeft(5)}');
  }
}
