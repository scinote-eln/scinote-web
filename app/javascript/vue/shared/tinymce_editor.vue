<template>
  <div>
    <textarea :id="textareaId" :placeholder="placeholder" ref="inputField"></textarea>
  </div>
</template>

<script>
/* global SmartAnnotation */

import tinyMCE from 'tinymce/tinymce';
import 'tinymce/models/dom';
import 'tinymce/icons/default';
import 'tinymce/themes/silver';

import 'tinymce/plugins/table';
import 'tinymce/plugins/autosave';
import 'tinymce/plugins/autoresize';
import 'tinymce/plugins/link';
import 'tinymce/plugins/advlist';
import 'tinymce/plugins/codesample';
import 'tinymce/plugins/code';
import 'tinymce/plugins/autolink';
import 'tinymce/plugins/lists';
import 'tinymce/plugins/image';
import 'tinymce/plugins/charmap';
import 'tinymce/plugins/anchor';
import 'tinymce/plugins/searchreplace';
import 'tinymce/plugins/wordcount';
import 'tinymce/plugins/visualblocks';
import 'tinymce/plugins/visualchars';
import 'tinymce/plugins/insertdatetime';
import 'tinymce/plugins/nonbreaking';
import 'tinymce/plugins/save';
import 'tinymce/plugins/help';
import 'tinymce/plugins/help/js/i18n/keynav/en';
import 'tinymce/plugins/quickbars';
import 'tinymce/plugins/directionality';

import './external_tinymce_plugins.js'; // Load external plugins

// Content styles, including inline UI like fake cursors
// All the above CSS files are loaded on to the page but these two must
// be loaded into the editor iframe so they are loaded as strings and passed
// to the init function.
import 'raw-loader';
import contentCss from '!!raw-loader!tinymce/skins/content/default/content.min.css';
import contentUiCss from '!!raw-loader!tinymce/skins/ui/tinymce-5/content.min.css';

const contentPStyle = 'p { margin: 0; padding: 0;}';
const contentBodyStyle = 'body { font-family: "SN Inter", "Open Sans", Arial, Helvetica, sans-serif }';
const contentStyle = [contentCss, contentUiCss, contentBodyStyle, contentPStyle].map((s) => s.toString()).join('\n');

export default {
  name: 'TinemcyEditor',
  props: {
    textareaId: {
      type: String,
      required: true
    },
    modelValue: {
      type: String,
      default: '',
      required: true
    },
    placeholder: {
      type: String,
      default: ''
    },
    plugins: {
      default: () => `
          table autoresize link advlist codesample code autolink lists
          charmap anchor searchreplace wordcount visualblocks visualchars
          insertdatetime nonbreaking save directionality help quickbars`
    },
    menubar: {
      default: 'file edit view insert format'
    },
    toolbar: {
      default: 'undo redo | insert | styleselect | bold italic | forecolor backcolor | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent '
    }
  },
  data() {
    return {
      editor: null
    };
  },
  mounted() {
    tinyMCE.init({
      selector: `#${this.textareaId}`,
      plugins: `${this.plugins} ${window.extraTinyMcePlugins || ''}`,
      menubar: this.menubar,
      skin: false,
      content_css: false,
      content_style: contentStyle,
      convert_urls: false,
      toolbar: window.customLightTinyMceToolbar || this.toolbar,
      contextmenu: '',
      promotion: false,
      menu: {
        insert: { title: 'Insert', items: 'charmap hr | nonbreaking | insertdatetime' }
      },
      autoresize_bottom_margin: 20,
      codesample_global_prismjs: true,
      codesample_languages: [
        { text: 'R', value: 'r' },
        { text: 'MATLAB', value: 'matlab' },
        { text: 'Python', value: 'python' },
        { text: 'JSON', value: 'javascript' },
        { text: 'HTML/XML', value: 'markup' },
        { text: 'JavaScript', value: 'javascript' },
        { text: 'CSS', value: 'css' },
        { text: 'PHP', value: 'php' },
        { text: 'Ruby', value: 'ruby' },
        { text: 'Java', value: 'java' },
        { text: 'C', value: 'c' },
        { text: 'C#', value: 'csharp' },
        { text: 'C++', value: 'cpp' }
      ],
      browser_spellcheck: true,
      branding: false,
      object_resizing: true,
      elementpath: false,
      quickbars_insert_toolbar: false,
      toolbar_mode: 'sliding',
      color_default_background: 'yellow',
      link_default_target: 'external',
      mobile: {
        menubar: 'file edit view insert format table'
      },
      link_target_list: [
        { title: 'New page', value: 'external' },
        { title: 'Same page', value: '_self' }
      ],
      style_formats: [
        {
          title: 'Headers',
          items: [
            { title: 'Header 1', format: 'h1' },
            { title: 'Header 2', format: 'h2' },
            { title: 'Header 3', format: 'h3' }
          ]
        },
        {
          title: 'Inline',
          items: [
            { title: 'Bold', icon: 'bold', format: 'bold' },
            { title: 'Italic', icon: 'italic', format: 'italic' },
            { title: 'Underline', icon: 'underline', format: 'underline' },
            { title: 'Strikethrough', icon: 'strike-through', format: 'strikethrough' },
            { title: 'Superscript', icon: 'superscript', format: 'superscript' },
            { title: 'Subscript', icon: 'subscript', format: 'subscript' },
            { title: 'Code', icon: 'sourcecode', format: 'code' }
          ]
        },
        {
          title: 'Blocks',
          items: [
            { title: 'Paragraph', format: 'p' },
            { title: 'Blockquote', format: 'blockquote' }
          ]
        },
        {
          title: 'Alignment',
          items: [
            { title: 'Left', icon: 'align-left', format: 'alignleft' },
            { title: 'Center', icon: 'align-center', format: 'aligncenter' },
            { title: 'Right', icon: 'align-right', format: 'alignright' },
            { title: 'Justify', icon: 'align-justify', format: 'alignjustify' }
          ]
        }
      ],
      init_instance_callback: (editor) => {
        const editorContainer = editor.getContainer();
        editorContainer.classList.add('tox-tinymce--loaded');
        editorContainer.classList.add('!h-[360px]');
        document.querySelectorAll('.tox-tinymce-aux').forEach((aux) => {
          aux.style.zIndex = '5000';
        });

        this.initCssOverrides(editor);

        SmartAnnotation.init($(editor.contentDocument.activeElement), false);
      },
      setup: (editor) => {
        editor.on('init', () => {
          editor.setContent(this.modelValue);
        });
        editor.on('change', () => {
          let content = editor.getContent();

          // Remove images
          content = content.replace(/<img[^>]*>/g, '');
          this.editorIframe(editor).contents().find('body img').remove();

          this.$emit('update:modelValue', content);
        });
      }
    });
  },
  beforeUnmount() {
    if (tinyMCE.activeEditor) {
      tinyMCE.activeEditor.remove();
    }
  },
  methods: {
    editorIframe(editor) {
      return $(`#${editor.id}`).next().find('.tox-edit-area iframe');
    },
    initCssOverrides(editor) {
      const editorIframe = this.editorIframe(editor);
      const primaryColor = '#104da9';
      const placeholderColor = '#98A2B3';
      editorIframe.contents().find('head').append(`<style type="text/css">
          img::-moz-selection{background:0 0}
          img::selection{background:0 0}

          .mce-content-body img[data-mce-selected]{outline:2px solid ${primaryColor}}
          .mce-content-body div.mce-resizehandle{background:transparent;border-color:transparent;box-sizing:border-box;height:10px;width:10px; position:absolute}
          .mce-content-body div.mce-resizehandle:hover{background:transparent}
          .mce-content-body div#mceResizeHandlenw{border-left: 2px solid ${primaryColor}; border-top: 2px solid ${primaryColor}}
          .mce-content-body div#mceResizeHandlene{border-right: 2px solid ${primaryColor}; border-top: 2px solid ${primaryColor}}
          .mce-content-body div#mceResizeHandlesw{border-left: 2px solid ${primaryColor}; border-bottom: 2px solid ${primaryColor}}
          .mce-content-body div#mceResizeHandlese{border-right: 2px solid ${primaryColor}; border-bottom: 2px solid ${primaryColor}}
          .mce-content-body:not([dir=rtl])[data-mce-placeholder]:not(.mce-visualblocks)::before {
            color: ${placeholderColor};
            opacity: 0.7;
          }
          h1 {font-size: 24px !important }
          h2 {font-size: 18px !important }
          h3 {font-size: 16px !important }
          #tinymce {
            overflow-y: auto !important;
          }
        </style>`);
      editorIframe.contents().find('head').append($('#font-css-pack').clone());
    }
  }
};
</script>
