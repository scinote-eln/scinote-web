import { texToPngDataUrl } from '../../mathjax.js';

tinymce.PluginManager.add('mathequation', function (editor) {

  function renderMathInEditor() {
    const doc = editor.getDoc();
    const spans = doc.querySelectorAll('.math-tex[data-latex]');
    spans.forEach((span) => {
      const latex = span.getAttribute('data-latex');
      if (span.querySelector('img')) return;
      texToPngDataUrl(latex, false).then(({ dataUrl, width, height }) => {
        const img = doc.createElement('img');
        img.src = dataUrl;
        img.width = width;
        img.height = height;
        img.alt = latex;
        span.innerHTML = '';
        span.appendChild(img);
      }).catch(() => {
        span.textContent = `[Invalid LaTeX: ${latex}]`;
      });
    });
  }

  function openDialog(existingLatex, targetNode) {
    editor.windowManager.open({
      title: existingLatex ? 'Edit Equation' : 'Insert Equation',
      body: {
        type: 'panel',
        items: [{ type: 'textarea', name: 'latex', label: 'LaTeX' }]
      },
      initialData: { latex: existingLatex || '' },
      buttons: [
        { type: 'cancel', text: 'Cancel' },
        { type: 'submit', text: existingLatex ? 'Update' : 'Insert', primary: true }
      ],
      onSubmit: function (api) {
        const latex = api.getData().latex.trim();
        if (!latex) { api.close(); return; }

        const html = `<span class="math-tex" data-latex="${escapeAttr(latex)}" contenteditable="false">⋯</span>&nbsp;`;

        if (targetNode) {
          targetNode.outerHTML = html;
        } else {
          editor.insertContent(html);
        }

        api.close();
        renderMathInEditor();
      }
    });
  }

  function escapeAttr(str) {
    return str.replace(/&/g, '&amp;').replace(/"/g, '&quot;');
  }

  editor.ui.registry.addButton('mathequation', {
    text: '∑',
    tooltip: 'Insert Equation',
    onAction: () => openDialog(null, null)
  });

  editor.on('dblclick', (e) => {
    const node = e.target.closest ? e.target.closest('.math-tex') : null;
    if (node) openDialog(node.getAttribute('data-latex'), node);
  });

  editor.on('SetContent', renderMathInEditor);
  editor.on('init', renderMathInEditor);

  return { getMetadata: () => ({ name: 'Math Equation Plugin' }) };
});
