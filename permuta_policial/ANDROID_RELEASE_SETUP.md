# Publicação do APK/AAB — Permuta Policial

Este guia lista o que **já está no código** e o que **só você pode fazer** (contas, chaves, consoles).

## O que já foi implementado no projeto

| Recurso | Comportamento |
|--------|----------------|
| **Google no APK** | Login nativo via `google_sign_in` → `POST /api/auth/google/native` |
| **Google na Web** | Continua OAuth pelo navegador (`/api/auth/google`) |
| **Microsoft** | APK e Web: navegador + deep link (`permutapolicial://` ou HTTPS) |
| **Push (FCM)** | `firebase_messaging` + registro em `POST /api/push/register` |
| **applicationId** | `br.com.permutapolicial.app` |
| **Assinatura release** | Lê `android/key.properties` (template em `key.properties.example`) |
| **Ícone** | Placeholder vetorial em `res/drawable/` (substitua por arte final) |

---

## Passo a passo — só você pode fazer

### 1. Banco de dados (produção)

Execute a seção **6. PUSH NOTIFICATIONS** em `MIGRATIONS_PENDENTES.sql` (ou o arquivo `backend_js/database/migrations/create_device_tokens.sql`).

Reinicie o backend após o deploy das novas rotas.

**Push (FCM HTTP v1)** — veja também `WEB_PUSH_SETUP.md`:

```env
FCM_PROJECT_ID=seu-projeto-firebase
FCM_SERVICE_ACCOUNT_PATH=./secrets/fcm-service-account.json
```

Crie a service account no Google Cloud com permissão **Firebase Cloud Messaging API Admin** e baixe a chave JSON.

### 2. Variáveis do backend (`.env`)

```env
GOOGLE_CLIENT_ID=...          # Web OAuth (já existente)
GOOGLE_CLIENT_SECRET=...
GOOGLE_ANDROID_CLIENT_ID=...  # Client ID tipo "Android" no Google Cloud
GOOGLE_SERVER_CLIENT_ID=... # Client ID tipo "Web" (mesmo usado como serverClientId no app)
```

O endpoint `/api/auth/google/native` aceita ID tokens cujo `aud` seja um desses três IDs.

### 3. Keystore de release (assinatura Play Store)

```powershell
cd permuta_policial\android
mkdir keystore -ErrorAction SilentlyContinue
keytool -genkey -v -keystore keystore\permuta-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias permuta
```

Copie `key.properties.example` → `key.properties` e preencha senhas/caminho.

**Nunca commite** `key.properties` nem o `.jks`.

### 4. Google Cloud Console — OAuth Android

1. [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials
2. Crie **OAuth client ID** tipo **Android**:
   - Package name: `br.com.permutapolicial.app`
   - SHA-1 **debug** (desenvolvimento):
     ```powershell
     keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
     ```
   - SHA-1 **release** (keystore que você criou no passo 3)
3. Anote o **Android Client ID** → `GOOGLE_ANDROID_CLIENT_ID` no backend
4. Use o **Web Client ID** existente como `GOOGLE_SERVER_CLIENT_ID` (backend) e no build do app (abaixo)

### 5. Firebase — Push notifications

1. [Firebase Console](https://console.firebase.google.com/) → novo projeto (ou use o existente)
2. Adicione app **Android** com package `br.com.permutapolicial.app`
3. Baixe `google-services.json` → salve em `android/app/google-services.json`
4. Ative **Cloud Messaging** no projeto
5. Obtenha os valores para o build Flutter (Project settings → Your apps):

```powershell
flutter build appbundle --release `
  --dart-define=ENV=prod `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=SEU_WEB_CLIENT_ID.apps.googleusercontent.com `
  --dart-define=FIREBASE_API_KEY=SUA_API_KEY `
  --dart-define=FIREBASE_APP_ID=1:123456:android:abc `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789 `
  --dart-define=FIREBASE_PROJECT_ID=seu-projeto
```

**Alternativa:** instale FlutterFire CLI e rode `flutterfire configure` — gera `lib/firebase_options.dart` com valores fixos (substitui o uso de `--dart-define`).

### 6. Ícone final do app

O projeto usa um ícone placeholder. Para arte profissional:

1. Coloque `assets/icon.png` (1024×1024)
2. Adicione ao `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.14.3
   flutter_launcher_icons:
     android: true
     image_path: assets/icon.png
   ```
3. Rode `dart run flutter_launcher_icons`

### 7. App Links (OAuth Microsoft / callbacks HTTPS)

Publique em `https://br.permutapolicial.com.br/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "br.com.permutapolicial.app",
    "sha256_cert_fingerprints": ["SHA256_DO_SEU_CERTIFICADO_RELEASE"]
  }
}]
```

SHA-256 do certificado release:
```powershell
keytool -list -v -keystore keystore\permuta-release.jks -alias permuta
```

### 8. Build e upload Play Console

```powershell
cd permuta_policial
flutter pub get
flutter build appbundle --release --dart-define=ENV=prod --dart-define=GOOGLE_SERVER_CLIENT_ID=...
```

Envie o `.aab` em [Google Play Console](https://play.google.com/console).

Checklist Play Store:
- Política de privacidade (URL pública)
- Data safety (dados coletados: e-mail, localização, fotos, etc.)
- Conta de teste para revisão
- Screenshots e descrição

### 9. Testar no dispositivo

```powershell
flutter run --dart-define=ENV=prod --dart-define=GOOGLE_SERVER_CLIENT_ID=SEU_WEB_CLIENT_ID.apps.googleusercontent.com
```

- **Google:** deve abrir seletor de conta nativo (sem Chrome)
- **Microsoft:** abre navegador e volta pelo deep link
- **Push:** após login, verifique no banco se há linha em `device_tokens`

---

## O que ainda não está no código (opcional / futuro)

- **Envio de push pelo backend** — implementado via FCM HTTP v1 (`push.sender.js`); disparos automáticos em match-alerts e mapa tático
- **Microsoft nativo (MSAL)** — continua via browser no APK
- **iOS** — este guia foca Android; iOS exige Apple Developer + APNs

---

## Resumo de comandos

| Ação | Comando |
|------|---------|
| APK debug | `flutter build apk --debug` |
| AAB release | `flutter build appbundle --release` + dart-defines |
| SHA-1 debug | `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android` |
| Analisar código | `flutter analyze` |
