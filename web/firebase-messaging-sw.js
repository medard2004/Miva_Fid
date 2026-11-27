// ─── Service Worker FCM — Miva Fid ──────────────────────────────
//
// Le backend envoie `webpush.notification` avec l'icône (logo du
// restaurant) et le titre/body. Le navigateur affiche la notification
// automatiquement et de manière FIABLE, même en arrière-plan profond
// ou navigateur fermé — contrairement aux data-only pushes dont la
// délivrance n'est pas garantie sur mobile.
//
// Le SDK Firebase (`firebase-messaging-compat.js`) est initialisé
// pour maintenir le push subscription, gérer le token refresh, et
// faire le lien `fcm_options.link` → notificationclick.
// ─────────────────────────────────────────────────────────────────

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

// ─── Fallback pour data-only pushes (edge case) ─────────────────
// Si un message arrive sans `webpush.notification` (ancien format,
// test manuel, etc.), on le traite ici manuellement.
messaging.onBackgroundMessage((payload) => {
  // Si le navigateur a déjà affiché la notification via
  // `webpush.notification`, ce callback n'est PAS appelé.
  // Il ne se déclenche que pour les data-only pushes.
  const data = payload.data || {};
  const title = data.title || 'Miva Fid';
  const body = data.body || '';

  if (!title && !body) return;

  const rawIcon = data.restaurant_logo || '';
  const icon = rawIcon && rawIcon.indexOf('ngrok') === -1
    ? rawIcon
    : '/icons/Icon-192.png';

  const tag = data.notification_id || data.type || 'miva-fid-push';

  return self.registration.showNotification(title, {
    body,
    icon,
    badge: '/icons/badge-96.png',
    tag,
    renotify: !!data.notification_id,
    vibrate: [200, 100, 200],
    data: {
      ...data,
      link: data.link || '/',
    },
  });
});

// ─── Clic sur la notification ───────────────────────────────────
// Gère la navigation quand l'utilisateur tape sur un push.
// Fonctionne pour les deux types de pushes (notification et data-only).
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  // Extraire le lien de destination.
  // Pour les pushes via `webpush.notification`, FCM place le payload
  // dans `notification.data.FCM_MSG`. Pour les data-only pushes gérés
  // par `onBackgroundMessage`, c'est dans `notification.data` directement.
  const notifData = event.notification.data || {};
  const fcmMsg = notifData.FCM_MSG || {};
  const fcmData = fcmMsg.data || {};

  const targetUrl =
    (fcmMsg.fcmOptions && fcmMsg.fcmOptions.link) ||
    fcmData.link ||
    notifData.link ||
    notifData.url ||
    '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      // Chercher un onglet existant de l'app pour le réutiliser
      for (const client of windowClients) {
        if ('focus' in client) {
          if ('navigate' in client && targetUrl && targetUrl !== '/') {
            client.navigate(targetUrl).catch(() => {});
          }
          return client.focus();
        }
      }
      // Sinon, ouvrir un nouvel onglet
      if (clients.openWindow) return clients.openWindow(targetUrl);
    })
  );
});
