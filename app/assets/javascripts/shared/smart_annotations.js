const escapeHtml = (unsafe) => (
  unsafe.replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')
);

window.renderSmartAnnotations = (text) => (
  text.replace(/\[#(.*?)~(.*?)~(\d+)\]/g, (match, label, type) => {
    const tag = encodeURIComponent(match.slice(1, -1));
    const safeLabel = escapeHtml(label);
    const safeType = escapeHtml(type);

    switch (type) {
      case 'rep_item':
        return `<a class="sa-link record-info-link" href="/sa?tag=${tag}"><span class="sa-type">INV</span>${safeLabel}</a>`;
      default:
        return `<a class="sa-link" href="/sa?tag=${tag}" target="_blank"><span class="sa-type">${safeType}</span>${safeLabel}</a>`;
    }
  })
);

window.renderElementSmartAnnotations = (element) => {
  element.innerHTML = window.renderSmartAnnotations(element.innerHTML);

  return true;
};
