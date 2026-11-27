importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD3U4izcYq8VLK6MSEAahJk9fJw1AF_EGQ',
  authDomain: 'mivafid-app.firebaseapp.com',
  projectId: 'mivafid-app',
  storageBucket: 'mivafid-app.firebasestorage.app',
  messagingSenderId: '829928583492',
  appId: '1:829928583492:web:b82f04f6cd51cc61dee711',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  // Le serveur envoie désormais un message data-only pour le Web (pas de
  // bloc `notification` ni `webpush.notification`). Title, body et icône
  // sont donc lus exclusivement depuis `payload.data`.
  const data = payload.data || {};
  const title = data.title || 'Miva Fid';
  const body = data.body || '';
  const image = data.image_url || undefined;
  const rawIcon = data.restaurant_logo || '';
  const icon = rawIcon && rawIcon.indexOf('ngrok') === -1 ? rawIcon : undefined;
  const tag = data.notification_id || data.type || 'miva-fid-push';
  const options = {
    body,
    ...(icon ? { icon } : {}),
    badge: '/icons/badge-96.png',
    ...(image ? { image } : {}),
    tag,
    renotify: !!data.notification_id,
    vibrate: [200, 100, 200],
    data: {
      ...data,
      link: payload.fcmOptions?.link || data.link || '/',
    },
  };
  return self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  const targetUrl =
    data.FCM_MSG?.fcmOptions?.link ||
    data.link ||
    data.url ||
    '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if ('focus' in client) {
          if ('navigate' in client && targetUrl && targetUrl !== '/') {
            client.navigate(targetUrl).catch(() => {});
          }
          return client.focus();
        }
      }
      if (clients.openWindow) return clients.openWindow(targetUrl);
    })
  );
});
