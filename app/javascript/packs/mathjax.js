import { mathjax } from '@mathjax/src/js/mathjax.js';
import { TeX } from '@mathjax/src/js/input/tex.js';
import { SVG } from '@mathjax/src/js/output/svg.js';
import { browserAdaptor } from '@mathjax/src/js/adaptors/browserAdaptor.js';
import { RegisterHTMLHandler } from '@mathjax/src/js/handlers/html.js';

// Required TeX packages — load explicitly since direct imports
// bypass the component/autoload system
import '@mathjax/src/js/input/tex/base/BaseConfiguration.js';
import '@mathjax/src/js/input/tex/ams/AmsConfiguration.js';
import '@mathjax/src/js/input/tex/newcommand/NewcommandConfiguration.js';
import '@mathjax/src/js/input/tex/noundefined/NoUndefinedConfiguration.js';

const adaptor = browserAdaptor();
RegisterHTMLHandler(adaptor);

const tex = new TeX({
  packages: ['base', 'ams', 'newcommand', 'noundefined'],
  formatError(jax, err) {
    console.error('MathJax TeX error:', err.message);
  }
});

const svg = new SVG({
  fontCache: 'local' // 'local' embeds glyph paths per-equation; safest for TinyMCE's iframe
});

// Blank document; we create/typeset nodes on demand
const html = mathjax.document('', {
  InputJax: tex,
  OutputJax: svg
});

/**
 * Converts a LaTeX string into an SVG DOM node.
 * @param {string} latex
 * @param {boolean} display - true for block/display style, false for inline
 * @returns {Element} the typeset node
 */
export function texToSvgNode(latex, display = false) {
  return html.convert(latex, { display, em: 16, ex: 8 });
}

export { adaptor };
