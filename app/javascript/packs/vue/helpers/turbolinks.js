function mountWithTurbolinks(app, target) {
  const originalHtml = document.querySelector(target).innerHTML;

  document.addEventListener('turbolinks:before-cache', () => {
    app.unmount();
    document.querySelector(target).innerHTML = originalHtml;
  }, { once: true });

  return app.mount(target);
}

export { mountWithTurbolinks };
