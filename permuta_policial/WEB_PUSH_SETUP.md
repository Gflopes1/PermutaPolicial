# Push notifications — Web e PWA

Guia para ativar notificações no **navegador mobile** e no **app instalado (PWA)**.

## O que já está no código

| Item | Descrição |
|------|-----------|
| `PushNotificationService` | Suporte FCM em Android, iOS e **Web** |
| `WebPushPermissionBanner` | Banner pedindo permissão após login (mobile web / PWA) |
| `web/firebase-messaging-sw.js` | Service Worker para push em segundo plano |
| `web/firebase-config.js` | Config Firebase usada pelo Service Worker |
| `POST /api/push/register` | Aceita `platform: 'web'` |

---

## O que você precisa configurar

### 1. Firebase Console — app Web

  1. [Firebase Console](https://console.firebase.google.com/) → seu projeto (o **mesmo** do Android, se já existir).
  2. **Add app** → **Web** (`</>`).
  3. Registre o domínio de produção, ex.: `br.permutapolicial.com.br`.
  4. Anote a **config do app Web** (apiKey, authDomain, projectId, storageBucket, messagingSenderId, appId).

  ### 2. Chave VAPID (obrigatória para Web)

  1. Firebase Console → **Project settings** → aba **Cloud Messaging**.
  2. Em **Web configuration** → **Web Push certificates** → **Generate key pair**.
  3. Copie a **Key pair** (string longa começando com `B...`) → será `FIREBASE_VAPID_KEY`.

  ### 3. Preencher `web/firebase-config.js`

  Edite `permuta_policial/web/firebase-config.js` com os valores do app **Web**:

```javascript
const FIREBASE_CONFIG = {
  apiKey: 'AIza...',
  authDomain: 'seu-projeto.firebaseapp.com',
  projectId: 'seu-projeto',
  storageBucket: 'seu-projeto.appspot.com',
  messagingSenderId: '123456789',
  appId: '1:123456789:web:abc123',
};
```

> Este arquivo **precisa estar preenchido em produção** para notificações com o app/PWA fechado.

### 4. Build / deploy Web com `--dart-define`

```powershell
cd permuta_policial

flutter build web --release `
  --dart-define=ENV=prod `
  --dart-define=FIREBASE_API_KEY=AIza... `
  --dart-define=FIREBASE_WEB_APP_ID=1:123:web:abc `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789 `
  --dart-define=FIREBASE_PROJECT_ID=seu-projeto `
  --dart-define=FIREBASE_AUTH_DOMAIN=seu-projeto.firebaseapp.com `
  --dart-define=FIREBASE_STORAGE_BUCKET=seu-projeto.appspot.com `
  --dart-define=FIREBASE_VAPID_KEY=B...sua-chave-vapid...
```

Use os mesmos valores de `firebase-config.js` (+ VAPID só no dart-define).

### 5. Backend — FCM HTTP v1

A API legacy (`FCM_SERVER_KEY` + `/fcm/send`) foi descontinuada. O backend usa **FCM HTTP v1** com **conta de serviço** (OAuth2).

#### 5.1 Criar service account no Google Cloud

1. [Google Cloud Console](https://console.cloud.google.com/) → projeto **vinculado ao Firebase**.
2. **IAM & Admin → Service Accounts → Create service account**.
3. Nome sugerido: `fcm-push-sender`.
4. Conceda a role **Firebase Cloud Messaging API Admin** (ou **Firebase Admin SDK Administrator Service Agent**).
5. Aba **Keys → Add key → JSON** → baixe o arquivo (ex.: `fcm-service-account.json`).

> Ative também a API **Firebase Cloud Messaging API** em APIs & Services, se ainda não estiver ativa.

#### 5.2 Variáveis no `.env` do backend

**Opção A — arquivo JSON no servidor (recomendado):**

```env
FCM_PROJECT_ID=seu-projeto-firebase
FCM_SERVICE_ACCOUNT_PATH=./secrets/fcm-service-account.json
FCM_WEB_LINK_BASE=https://br.permutapolicial.com.br
```

**Opção B — JSON inline (Docker/CI):**

```env
FCM_PROJECT_ID=seu-projeto-firebase
FCM_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"...","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...@....iam.gserviceaccount.com",...}
```

Também aceita `GOOGLE_APPLICATION_CREDENTIALS` no lugar de `FCM_SERVICE_ACCOUNT_PATH`.

`FCM_PROJECT_ID` pode ser omitido se você já tiver `FIREBASE_PROJECT_ID` no `.env`.

**Nunca commite** o JSON da service account.

#### 5.3 Reiniciar o backend

```powershell
cd backend_js
npm install
npm run dev
```

Tokens inválidos (`UNREGISTERED`, etc.) são removidos automaticamente de `device_tokens`.

### 6. Banco de dados

Tabela `device_tokens` (migration `create_device_tokens.sql`) — já suporta `platform = 'web'`.

### 7. Servidor / HTTPS

- Push Web **só funciona em HTTPS** (ou `localhost` em dev).
- Confirme que estes arquivos são servidos na raiz do site:
  - `/firebase-messaging-sw.js`
  - `/firebase-config.js`
  - `/manifest.json`

### 8. iOS Safari (PWA)

- Usuário deve **Adicionar à Tela de Início**.
- Notificações Web Push no iOS exigem **iOS 16.4+** e app instalado como PWA.
- O banner adapta o texto quando detecta modo PWA (`display-mode: standalone`).

---

## Testar

1. Deploy com config preenchida.
2. Abra `https://br.permutapolicial.com.br` no **Chrome Android** (ou Safari iOS com PWA instalado).
3. Faça login → deve aparecer o banner **Ativar notificações**.
4. Aceite → verifique no banco:

```sql
SELECT * FROM device_tokens WHERE platform = 'web' ORDER BY atualizado_em DESC LIMIT 5;
```

5. Envie push de teste pelo Firebase Console (Cloud Messaging → Send test message) usando o token FCM.

---

## Comportamento do banner

- Aparece em **mobile web** ou **PWA**, após login, se permissão = `default`.
- **Agora não** oculta por 7 dias.
- Texto diferente para PWA instalado vs aba do navegador.

---

## Opcional — `flutterfire configure`

Se preferir gerar arquivos automaticamente:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

Depois copie a config Web gerada para `firebase-config.js` e ajuste os `--dart-define` do CI/CD.
