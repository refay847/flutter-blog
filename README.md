# Blogspace Flutter App

Flutter mobile client for the Laravel/Sanctum API:
`https://blog-2.wasmer.app/api/`

## Architecture
- `core/`: API client, storage, theme, reusable widgets
- `features/auth/`: auth data/domain/presentation
- `features/blogs/`: blogs data/domain/presentation
- `features/home/`: authenticated shell/profile
- `routing/`: GoRouter configuration

State management: Riverpod.
Networking: Dio.
Auth persistence: SharedPreferences.
Image upload: image_picker + Dio multipart.

## Run
```bash
flutter pub get
flutter run -d <device>
```

## Important backend requirement
Your Laravel app must expose public storage files. Run on the server:
```bash
php artisan storage:link
```
The app expects image URLs like:
`https://blog-2.wasmer.app/storage/blogs/<filename>`

## Update flow
Laravel update is sent as `POST /blogs/{id}` with `_method=PUT` when an image may be included. This avoids multipart PUT parsing problems in PHP/Laravel deployments.
