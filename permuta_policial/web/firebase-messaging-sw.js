/* eslint-disable no-undef */
// Service Worker FCM — notificações em segundo plano (navegador / PWA instalado).

importScripts('/firebase-config.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

if (typeof FIREBASE_CONFIG !== 'undefined' && FIREBASE_CONFIG.apiKey) {
  firebase.initializeApp(FIREBASE_CONFIG);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage(function (payload) {
    // 1. Evitar Duplicidade: Se o payload veio com 'notification', 
    // o próprio Firebase já vai exibir o alerta automaticamente.
    if (payload.notification) {
      console.log('Firebase já exibiu a notificação. Ignorando a manual.');
      return; 
    }

    // 2. Só cria a notificação manual se for uma mensagem 'Data-Only' 
    // (onde o backend não enviou a chave 'notification')
    const title = payload.data?.title || 'Permuta Policial';
    const options = {
      body: payload.data?.body || '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      data: payload.data || {},
      tag: (payload.data && payload.data.tipo) || 'permuta',
    };
    return self.registration.showNotification(title, options);
  });
}

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const data = event.notification.data || {};
  let url = '/dashboard';

  const tipo = data.tipo;
  const ref = data.referencia_id;

  if (tipo === 'NOVA_MENSAGEM') {
    url = ref ? '/chat/conversa/' + ref : '/dashboard';
  } else if (tipo === 'NOVO_MATCH') {
    url = '/permutas';
  } else if (tipo === 'SOLICITACAO_CONTATO') {
    url = '/notificacoes';
  } else if (tipo === 'SOLICITACAO_CONTATO_ACEITA') {
    url = '/notificacoes';
  } else if (tipo === 'MAPA_TATICO_CONVITE') {
    url = '/mapa-tatico';
  } else if (tipo && String(tipo).indexOf('MAPA_TATICO') === 0) {
    url = ref ? '/mapa-tatico/ponto/' + ref : '/mapa-tatico';
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if ('focus' in client) {
          if ('navigate' in client) {
            return client.navigate(url).then(function () {
              return client.focus();
            });
          }
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(url);
      }
    })
  );
});
