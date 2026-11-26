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
  const options = {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };
  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow('/');
    })
  );
});
