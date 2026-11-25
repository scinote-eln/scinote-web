import { h, getCurrentInstance, camelize } from 'vue';
import bundledJspreadsheet from 'jspreadsheet';

// jspreadsheet keeps its interaction state (focused worksheet, formula reference picker, worksheet
// name registry) in module scope and binds its document/window listeners to that state. Every pack
// bundles its own copy of the library, and Turbolinks re-executes pack scripts on each visit, so
// every visit to a page with tables would add another live jspreadsheet instance whose listeners are
// never removed. Those stale listeners still handle mousedown on the new page's cells without seeing
// the current instance's formula session, and close the cell editor instead of letting the click
// insert a reference. All packs and visits therefore share the first instance that was loaded.
if (!window.SciNoteJspreadsheet) {
  window.SciNoteJspreadsheet = bundledJspreadsheet;
}

export const jspreadsheet = window.SciNoteJspreadsheet;

// Replacements for the @jspreadsheet/vue components, which always use their own bundled jspreadsheet
// copy instead of the shared instance

export const Worksheet = {
  name: 'Worksheet'
};

export const Spreadsheet = {
  inheritAttrs: false,
  mounted() {
    const { attrs, slots } = getCurrentInstance();

    const options = {};
    Object.keys(attrs).forEach((key) => {
      options[camelize(key)] = attrs[key];
    });

    if (slots && typeof slots.default === 'function') {
      options.worksheets = slots.default().reduce((acc, vnode) => {
        if (vnode.type.name === 'Worksheet') {
          const worksheetProps = {};

          Object.keys(vnode.props || {}).forEach((key) => {
            worksheetProps[camelize(key)] = vnode.props[key];
          });

          acc.push({
            minDimensions: [4, 4],
            ...worksheetProps
          });
        }
        return acc;
      }, []);
    } else if (attrs.worksheets) {
      options.worksheets = attrs.worksheets;
    }

    if (attrs.license) {
      jspreadsheet.setLicense(attrs.license);
    }
    if (attrs.extensions) {
      jspreadsheet.setExtensions(attrs.extensions);
    }
    if (attrs.id) {
      this.$refs.container.id = attrs.id;
    }

    this.el = this.$refs.container;

    this.current = jspreadsheet(this.$refs.container, options);
  },
  setup() {
    return () => h('div', { ref: 'container' });
  }
};
