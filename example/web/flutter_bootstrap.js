{{flutter_js}}
{{flutter_build_config}}

if ('serviceWorker' in navigator) {
  navigator.serviceWorker
      .getRegistrations()
      .then((registrations) =>
          Promise.all(registrations.map((registration) => registration.unregister())))
      .then(() => {
    if (navigator.serviceWorker.controller) {
      window.location.reload();
      return;
    }
    _flutter.loader.load();
  })
      .catch(() => _flutter.loader.load());
} else {
  _flutter.loader.load();
}
