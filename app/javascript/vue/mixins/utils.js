/* global ActiveStorage GLOBAL_CONSTANTS Promise i18n */

export default {
  methods: {
    stripHtml(html) {
      let tmp = document.createElement("DIV");
      tmp.innerHTML = html;
      return tmp.textContent || tmp.innerText || "";
    },
    truncate(text, length) {
      if (text.length > length) {
        return text.substring(0, length) + '...';
      }

      return text;
    },
    numberWithSpaces(x) {
      return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ");
    }
  }
};
