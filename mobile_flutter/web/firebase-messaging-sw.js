/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyAbYh9oAV4H5EPZJytRZq4HM4DG7q0iYIc',
  authDomain: 'bloquinhodigital.firebaseapp.com',
  projectId: 'bloquinhodigital',
  storageBucket: 'bloquinhodigital.firebasestorage.app',
  messagingSenderId: '16911555826',
  appId: '1:16911555826:web:addd018a6120ee67ef846b',
  measurementId: 'G-K6H8VS1F95',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload?.notification?.title || 'Nova notificacao';
  const body = payload?.notification?.body || 'Voce recebeu uma mensagem.';
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
  });
});
