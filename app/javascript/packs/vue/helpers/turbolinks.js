function handleTurbolinks(app) {
  document.addEventListener('turbolinks:before-cache', () => {
    app.unmount();
  }, { once: true });
}

export { handleTurbolinks };