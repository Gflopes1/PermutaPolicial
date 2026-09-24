// Configuração Firebase Web — Service Worker + app Flutter (runtime).
// Preencha com Firebase Console → Project settings → Web app.
// A chave vapidKey é obrigatória para o banner pedir permissão no celular.

var FIREBASE_CONFIG = {
  apiKey: 'AIzaSyBsnmIFAqo4FNxtFwAe7aTLAeNA5G_ymtQ',
  authDomain: 'permuta-policial-ofc.firebaseapp.com',
  projectId: 'permuta-policial-ofc',
  storageBucket: 'permuta-policial-ofc.firebasestorage.app',
  messagingSenderId: '103953802498',
  appId: '1:372616401008:web:ab5e5adf48ea3d102724b5',
};

// Usado pelo Flutter Web em runtime (PushNotificationService) — inclua a VAPID key!
var FIREBASE_PUSH_CONFIG = {
  apiKey: FIREBASE_CONFIG.apiKey,
  authDomain: FIREBASE_CONFIG.authDomain,
  projectId: FIREBASE_CONFIG.projectId,
  storageBucket: FIREBASE_CONFIG.storageBucket,
  messagingSenderId: FIREBASE_CONFIG.messagingSenderId,
  appId: FIREBASE_CONFIG.appId,
  vapidKey: 'BHqUBZLSNKwYg-PPsTXJNoSoQmp8vePYeaUxiyC7EpN6BeqI4SOeL4x4jR8bb9BCbJx98JoMxgUYPMQLAL_acrs',
};
