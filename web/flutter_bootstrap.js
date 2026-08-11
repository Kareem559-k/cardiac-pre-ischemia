{{flutter_js}}
{{flutter_build_config}}

(function () {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then((registrations) => {
      for (const registration of registrations) {
        registration.unregister();
      }
    });
  }

  _flutter.loader.load({
    serviceWorkerSettings: null,
  });
})();
