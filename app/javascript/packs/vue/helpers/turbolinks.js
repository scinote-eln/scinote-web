function mountWithTurbolinks(app, target, callback = null) {
  const originalHtml = document.querySelector(target).innerHTML;
  const cacheDisabled = document.querySelector('#cache-directive');
  const event = cacheDisabled ? 'turbolinks:before-render' : 'turbolinks:before-cache';

  document.addEventListener(event, () => {
    app.unmount();
    if (document.querySelector(target)) {
      document.querySelector(target).innerHTML = originalHtml;
    }
    if (callback) callback();
  }, { once: true });

  return app.mount(target);
}

export { mountWithTurbolinks };
