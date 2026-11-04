# DON'T TOUCH THE FUTURE
Your past is chasing you. Minimalist arcade game (Flutter + Flame).

## Phase 1 status: Foundation
- Project structure, design tokens, theme, routing
- Storage + settings services (SharedPreferences)
- Game state machine (pure Dart) and MovementSample model
- Splash -> Home -> Gameplay (empty Flame arena)

## Setup
1. `flutter create --org com.yourname --project-name dont_touch_the_future .`
2. `flutter pub add flame shared_preferences`
3. `flutter pub get`
4. `flutter analyze && flutter test`
5. `flutter run`
