import 'package:dont_touch_the_future/features/gameplay/game/systems/effects_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EffectsSystem particles', () {
    test('burst spawns the requested number of particles', () {
      final e = EffectsSystem();
      e.burst(0, 0, count: 20, speed: 100, color: EffectColor.shard);
      expect(e.activeParticles, 20);
    });

    test('pool never exceeds its capacity', () {
      final e = EffectsSystem(particleCapacity: 30);
      for (var i = 0; i < 10; i++) {
        e.burst(0, 0, count: 20, speed: 100, color: EffectColor.danger);
      }
      expect(e.activeParticles, 30);
    });

    test('particles expire and free their slots', () {
      final e = EffectsSystem();
      e.burst(0, 0, count: 25, speed: 100, color: EffectColor.white, life: 0.5);
      for (var i = 0; i < 100; i++) {
        e.update(0.05); // 5 seconds, longer than any lifetime
      }
      expect(e.activeParticles, 0);
    });

    test('particles move away from the origin', () {
      final e = EffectsSystem();
      e.burst(100, 100, count: 1, speed: 200, color: EffectColor.white);
      final x0 = e.particleX(0);
      final y0 = e.particleY(0);
      e.update(0.05);
      final moved = (e.particleX(0) - x0).abs() + (e.particleY(0) - y0).abs();
      expect(moved > 0, isTrue);
    });

    test('ring burst is evenly spaced and deterministic in count', () {
      final e = EffectsSystem();
      e.burst(0, 0, count: 12, speed: 100, color: EffectColor.white, ring: true);
      expect(e.activeParticles, 12);
    });

    test('reduced motion spawns fewer particles and no trail', () {
      final e = EffectsSystem()..reducedMotion = true;
      e.burst(0, 0, count: 30, speed: 100, color: EffectColor.white);
      expect(e.activeParticles, 10);
      final before = e.activeParticles;
      e.emitTrail(0, 0, 1);
      expect(e.activeParticles, before);
    });

    test('trail emits at a limited rate', () {
      final e = EffectsSystem();
      e.emitTrail(0, 0, 0.01);
      expect(e.activeParticles, 0);
      e.emitTrail(0, 0, 0.03);
      expect(e.activeParticles, 1);
    });
  });

  group('EffectsSystem shake and flash', () {
    test('shake is bounded by its amplitude and decays to zero', () {
      final e = EffectsSystem();
      e.shake(amplitude: 10, duration: 0.4);
      for (var i = 0; i < 8; i++) {
        e.update(0.05);
        expect(e.shakeX.abs() <= 10, isTrue);
        expect(e.shakeY.abs() <= 10, isTrue);
      }
      e.update(0.5);
      expect(e.shakeX, 0);
      expect(e.shakeY, 0);
    });

    test('shake does nothing in reduced motion', () {
      final e = EffectsSystem()..reducedMotion = true;
      e.shake(amplitude: 10);
      e.update(0.05);
      expect(e.shakeX, 0);
      expect(e.shakeY, 0);
    });

    test('impact flash fades out, and is softer in reduced motion', () {
      final e = EffectsSystem();
      e.impactFlash(0.5);
      expect(e.flash, 0.5);
      e.update(1);
      expect(e.flash, 0);

      final r = EffectsSystem()..reducedMotion = true;
      r.impactFlash(0.5);
      expect(r.flash <= 0.12, isTrue);
    });
  });

  group('EffectsSystem floating texts and reset', () {
    test('floating text rises, then deactivates', () {
      final e = EffectsSystem();
      e.spawnText(10, 100, '+50', duration: 0.5);
      expect(e.texts.any((t) => t.active), isTrue);
      e.update(0.1);
      final t = e.texts.firstWhere((t) => t.active);
      expect(t.y < 100, isTrue);
      e.update(1);
      expect(e.texts.any((t) => t.active), isFalse);
    });

    test('text pool recycles the oldest slot when full', () {
      final e = EffectsSystem(textCapacity: 2);
      e.spawnText(0, 0, 'a');
      e.update(0.2);
      e.spawnText(0, 0, 'b');
      e.spawnText(0, 0, 'c'); // pool full -> recycles the oldest ('a')
      final labels = e.texts.map((t) => t.text).toList();
      expect(labels.contains('c'), isTrue);
      expect(labels.contains('a'), isFalse);
    });

    test('reset clears particles, shake, flash and texts', () {
      final e = EffectsSystem();
      e.burst(0, 0, count: 10, speed: 50, color: EffectColor.white);
      e.shake(amplitude: 5);
      e.impactFlash();
      e.spawnText(0, 0, 'x');
      e.reset();
      expect(e.activeParticles, 0);
      expect(e.flash, 0);
      expect(e.texts.any((t) => t.active), isFalse);
    });
  });
}
