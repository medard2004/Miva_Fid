// ─── Service Worker FCM + PWA Offline Cache — Miva Fid ──────────
//
// Ce Service Worker assure deux missions clés :
// 1. NOTIFICATIONS PUSH FCM :
//    - Reçoit `webpush.notification` avec icône (logo du restaurant).
//    - Gère `notificationclick` pour ouvrir/focaliser l'application.
//    - Gère `onBackgroundMessage` comme fallback pour les messages data-only.
//
// 2. SUPPORT COMPLET HORS-LIGNE (OFFLINE PWA) :
//    - Met en cache les fichiers statiques de l'application (index.html,
//      flutter_bootstrap.js, main.dart.js, fonts, manifests, icons).
//    - En cas d'absence de connexion réseau (mode hors-ligne / avion),
//      sert immédiatement l'application depuis le cache local (Cache-First).
//    - Permet à l'utilisateur de charger l'application et de consulter
//      toutes ses données locales (cartes, tampons, récompenses, historique).
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
messaging.onBackgroundMessage((payload) => {
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
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

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

// ═════════════════════════════════════════════════════════════════
// ─── PWA OFFLINE CACHE (Accès hors ligne complet) ───────────────
// ═════════════════════════════════════════════════════════════════

const OFFLINE_CACHE_NAME = 'mivafid-offline-v2';

// Fichiers vitaux à pré-charger dès l'installation du Service Worker
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/badge-96.png'
];

self.addEventListener('install', (event) => {
  // Prise en charge immédiate
  self.skipWaiting();
  event.waitUntil(
    caches.open(OFFLINE_CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_URLS).catch((err) => {
        console.warn('[PWA SW] Pré-mise en cache partielle:', err);
      });
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          // Supprime les anciens caches offline tout en préservant Firebase
          if (key !== OFFLINE_CACHE_NAME && key.indexOf('firebase') === -1) {
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Interception des requêtes HTTP pour le mode hors ligne
self.addEventListener('fetch', (event) => {
  const request = event.request;

  // On n'intercepte que les requêtes GET
  if (request.method !== 'GET') return;

  const url = new URL(request.url);

  // 1. Ne JAMAIS intercepter les requêtes API (gérées par Dio + cache offline Dart)
  if (url.pathname.startsWith('/api/')) return;

  // 2. Ne pas bloquer les requêtes Firebase cloud messaging ou googleapis externes
  if (url.hostname.includes('googleapis.com') ||
      url.hostname.includes('gstatic.com') ||
      url.hostname.includes('firebaseio.com') ||
      url.hostname.includes('firebasestorage.app')) {
    return;
  }

  // 3. Navigation HTML (changement de page ou rechargement hors-ligne)
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request).catch(() => {
        // En cas de coupure réseau, on sert index.html depuis le cache
        return caches.match('/index.html').then((matching) => {
          return matching || caches.match('/');
        });
      })
    );
    return;
  }

  // 4. Requêtes d'assets statiques (JS, WASM, CSS, Images, Polices)
  if (url.origin === self.location.origin) {
    event.respondWith(
      caches.match(request).then((cachedResponse) => {
        // Si présent en cache, servir immédiatement
        if (cachedResponse) {
          // Si le réseau est disponible, rafraîchir le cache en tâche de fond (stale-while-revalidate discret)
          fetch(request).then((networkResponse) => {
            if (networkResponse && networkResponse.status === 200 && networkResponse.type === 'basic') {
              caches.open(OFFLINE_CACHE_NAME).then((cache) => {
                cache.put(request, networkResponse);
              });
            }
          }).catch(() => {});
          return cachedResponse;
        }

        // Sinon aller chercher sur le réseau et sauvegarder en cache
        return fetch(request).then((networkResponse) => {
          if (!networkResponse || networkResponse.status !== 200 || networkResponse.type !== 'basic') {
            return networkResponse;
          }
          const responseToCache = networkResponse.clone();
          caches.open(OFFLINE_CACHE_NAME).then((cache) => {
            cache.put(request, responseToCache);
          });
          return networkResponse;
        }).catch(() => {
          // Échec réseau : tentative de repli pour les images ou l'index
          if (request.destination === 'image') {
            return caches.match('/icons/Icon-192.png');
          }
          return null;
        });
      })
    );
  }
});
