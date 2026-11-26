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
  const title = payload.notification?.title || payload.data?.title || 'Miva Fid';
  const body = payload.notification?.body || payload.data?.body || '';
  const image = payload.notification?.image || payload.data?.image_url || undefined;
  const icon = payload.notification?.icon || payload.data?.restaurant_logo || '/icons/Icon-192.png';
  const tag = payload.data?.notification_id || payload.data?.type || 'miva-fid-push';
  const options = {
    body,
    icon,
    badge: '/icons/badge-96.png',
    ...(image ? { image } : {}),
    tag,
    vibrate: [200, 100, 200],
    data: {
      ...(payload.data || {}),
      link: payload.fcmOptions?.link || payload.data?.link || '/',
    },
  };
  self.registration.showNotification(title, options);
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
