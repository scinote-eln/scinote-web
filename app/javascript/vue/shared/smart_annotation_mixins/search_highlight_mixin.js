import escapeHtml from '../escape_html.js';

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export default {
  methods: {
    highlightMatch(text) {
      const safeText = escapeHtml(text || '');
      const query = (this.query || '').trim();
      if (!query) return safeText;

      const pattern = new RegExp(escapeRegExp(escapeHtml(query)), 'ig');
      return safeText.replace(pattern, (match) => `<span class=" font-bold">${match}</span>`);
    }
  }
};
