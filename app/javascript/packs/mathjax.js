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
  fontCache: 'none',
  linebreaks: { inline: false }
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

// Matches the `ex: 8` metric passed to html.convert() above, so the rasterized
// pixel size lines up with the size MathJax assumed while laying out the equation.
const PX_PER_EX = 8;
const RETINA_SCALE = 3;
const EQUATION_COLOR = '#1a1a1a';

/**
 * Converts a LaTeX string into a PNG data URL. Rendering to a raster image (rather than
 * keeping the live SVG in the saved content) sidesteps rich-text editors/sanitizers that
 * restrict inline SVG, at the cost of the image no longer inheriting the surrounding
 * text color.
 * @param {string} latex
 * @param {boolean} display - true for block/display style, false for inline
 * @returns {Promise<{dataUrl: string, width: number, height: number}>} the PNG data URL
 *   and the CSS pixel size (at 1x) the <img> should be displayed at
 */
export function texToPngDataUrl(latex, display = false) {
  const svgNode = texToSvgNode(latex, display).querySelector('svg');

  // The SVG inherits its color from the surrounding text via currentColor; a rasterized
  // image can't do that, so force a fixed, readable color before rendering to canvas.
  const colorGroup = svgNode.querySelector('g[fill="currentColor"]');
  if (colorGroup) {
    colorGroup.setAttribute('fill', EQUATION_COLOR);
    colorGroup.setAttribute('stroke', EQUATION_COLOR);
  }

  const width = Math.ceil(parseFloat(svgNode.getAttribute('width')) * PX_PER_EX);
  const height = Math.ceil(parseFloat(svgNode.getAttribute('height')) * PX_PER_EX);
  const svgString = new XMLSerializer().serializeToString(svgNode);
  const svgDataUrl = `data:image/svg+xml;base64,${btoa(unescape(encodeURIComponent(svgString)))}`;

  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement('canvas');
      canvas.width = width * RETINA_SCALE;
      canvas.height = height * RETINA_SCALE;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      resolve({ dataUrl: canvas.toDataURL('image/png'), width, height });
    };
    img.onerror = () => reject(new Error(`Failed to rasterize equation: ${latex}`));
    img.src = svgDataUrl;
  });
}

export { adaptor };
