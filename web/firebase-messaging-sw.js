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

// ─── Interception TOTALE du push event ──────────────────────────
// Le SDK firebase-messaging-compat.js enregistre son propre listener
// sur l'événement `push`. Quand le payload contient un bloc
// `notification` (même vide), le SDK crée automatiquement une
// notification avec l'icône par défaut du manifest (le rond gris M)
// AVANT d'appeler `onBackgroundMessage`.
//
// Pour avoir le contrôle complet de l'icône, on intercepte l'événement
// `push` en premier (addEventListener avec capture), on construit
// notre propre notification avec le restaurant_logo, puis on empêche
// le SDK de créer la sienne en swallowant le default.
self.addEventListener('push', function(event) {
  // Extraire le payload brut envoyé par FCM
  let payload;
  try {
    payload = event.data ? event.data.json() : {};
  } catch (e) {
    return; // Laisser le SDK gérer les payloads non-JSON
  }

  // Extraire les données depuis toutes les sources possibles
  // Le payload FCM peut avoir la structure :
  //   { data: {...} }                     → data-only
  //   { notification: {...}, data: {...} } → notification + data
  //   { FCM_MSG: { data: {...}, notification: {...} } } → wrapped
  const fcmMsg = payload.FCM_MSG || payload;
  const data = fcmMsg.data || payload.data || {};
  const notif = fcmMsg.notification || payload.notification || {};

  // Si ce n'est pas un message FCM reconnu, laisser le SDK gérer
  if (!data.type && !notif.title && !data.title) {
    return;
  }

  // Construire la notification nous-mêmes
  const title = data.title || notif.title || 'Miva Fid';
  const body = data.body || notif.body || '';
  const image = data.image_url || notif.image || undefined;
  const rawIcon = data.restaurant_logo || '';
  const icon = rawIcon && rawIcon.indexOf('ngrok') === -1 ? rawIcon : '/icons/Icon-192.png';
  const tag = data.notification_id || data.type || 'miva-fid-push';

  const options = {
    body,
    icon,
    badge: '/icons/badge-96.png',
    ...(image ? { image } : {}),
    tag,
    renotify: !!data.notification_id,
    vibrate: [200, 100, 200],
    data: {
      ...data,
      link: (fcmMsg.fcmOptions && fcmMsg.fcmOptions.link)
        || data.link
        || '/',
    },
  };

  // Afficher notre notification et empêcher le SDK d'en créer une autre
  event.stopImmediatePropagation();
  event.waitUntil(self.registration.showNotification(title, options));
}, true); // ← `true` = capture phase, s'exécute AVANT le listener du SDK

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
