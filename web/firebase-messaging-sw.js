importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyBBpjSJSA4H8C12IYbch_GHfvb78cAgKkE",
    authDomain: "themuzaksfood.firebaseapp.com",
    projectId: "themuzaksfood",
    storageBucket: "themuzaksfood.firebasestorage.app",
    messagingSenderId: "756706863472",
    appId: "1:756706863472:web:67619fa2c184c4b44087b5",
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});