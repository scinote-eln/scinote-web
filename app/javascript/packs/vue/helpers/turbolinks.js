function mountWithTurbolinks(app, target, callback = null) {
  const originalHtml = document.querySelector(target).innerHTML;

  document.addEventListener('turbolinks:before-cache', () => {
    app.unmount();
    if (document.querySelector(target)) {
      document.querySelector(target).innerHTML = originalHtml;
    }
    if (callback) callback();
  }, { once: true });

  return app.mount(target);
}

export { mountWithTurbolinks };
