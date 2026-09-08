import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/animation/pet_pose.dart';

void main() {
  group('PetPose.combine', () {
    test('offsets and rotation add, scales multiply, opacity multiplies', () {
      const a = PetPose(dx: 0.1, dy: -0.2, rotation: 0.3, scaleX: 1.1, scaleY: 0.9, opacity: 0.8);
      const b = PetPose(dx: 0.05, dy: 0.05, rotation: -0.1, scaleX: 1.05, scaleY: 1.05, opacity: 0.5);

      final combined = a.combine(b);

      expect(combined.dx, closeTo(0.15, 1e-9));
      expect(combined.dy, closeTo(-0.15, 1e-9));
      expect(combined.rotation, closeTo(0.2, 1e-9));
      expect(combined.scaleX, closeTo(1.1 * 1.05, 1e-9));
      expect(combined.scaleY, closeTo(0.9 * 1.05, 1e-9));
      expect(combined.opacity, closeTo(0.4, 1e-9));
    });

    test('combining with rest is a no-op on either side', () {
      const pose = PetPose(dx: 0.2, dy: 0.1, rotation: 0.4, scaleX: 1.2, scaleY: 0.8, opacity: 0.6);

      expect(pose.combine(PetPose.rest), pose);
      expect(PetPose.rest.combine(pose), pose);
    });

    test('rest combined with rest is rest', () {
      expect(PetPose.rest.combine(PetPose.rest), PetPose.rest);
    });
  });

  group('PetPoseTween', () {
    test('lerps every field independently', () {
      final tween = PetPoseTween(
        begin: const PetPose(dx: 0, dy: 0, rotation: 0, scaleX: 1, scaleY: 1, opacity: 1),
        end: const PetPose(dx: 1, dy: -1, rotation: 2, scaleX: 2, scaleY: 0.5, opacity: 0),
      );

      final mid = tween.lerp(0.5);

      expect(mid.dx, closeTo(0.5, 1e-9));
      expect(mid.dy, closeTo(-0.5, 1e-9));
      expect(mid.rotation, closeTo(1.0, 1e-9));
      expect(mid.scaleX, closeTo(1.5, 1e-9));
      expect(mid.scaleY, closeTo(0.75, 1e-9));
      expect(mid.opacity, closeTo(0.5, 1e-9));
    });

    test('lerp(0) is begin and lerp(1) is end', () {
      const begin = PetPose(dx: 0.1, dy: 0.2, rotation: 0.3, scaleX: 1.1, scaleY: 1.2, opacity: 0.9);
      const end = PetPose(dx: 0.4, dy: 0.5, rotation: 0.6, scaleX: 1.4, scaleY: 1.5, opacity: 0.4);
      final tween = PetPoseTween(begin: begin, end: end);

      expect(tween.lerp(0), begin);
      expect(tween.lerp(1), end);
    });
  });

  test('PetPose equality and hashCode are field-wise', () {
    const a = PetPose(dx: 0.1, dy: 0.2, rotation: 0.3, scaleX: 1.1, scaleY: 0.9, opacity: 0.8);
    const b = PetPose(dx: 0.1, dy: 0.2, rotation: 0.3, scaleX: 1.1, scaleY: 0.9, opacity: 0.8);
    const c = PetPose(dx: 0.15, dy: 0.2, rotation: 0.3, scaleX: 1.1, scaleY: 0.9, opacity: 0.8);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
