# DON'T TOUCH THE FUTURE
Your past is chasing you. Minimalist arcade game (Flutter + Flame).

## Phase 2 status: Core gameplay (plain visuals)
- GameSession (pure Dart): clock, player, echo, shards, obstacles, scoring, state
- MovementHistory ring buffer + exact 3 s Future Echo (interpolated)
- Difficulty phases, safe SpawnManager, circle collisions
- Stats persistence (best score/time, games, shards)
- Basic HUD / Pause / Game Over overlays (polish in Phase 3)

## Run
1. `flutter pub get`
2. `flutter analyze && flutter test`
3. `flutter run`
