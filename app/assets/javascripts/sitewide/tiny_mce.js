var TinyMCE = (function() {
  'use strict';

  function initHighlightjs() {
    $('pre code [class^=language]').each(function(i, block) {
      if(!$(block).hasClass('hljs')) {
        hljs.highlightBlock(block);
      }
    });
  }

  return Object.freeze({
    init : function() {
      if (typeof tinyMCE != 'undefined') {
        tinyMCE.init({
          selector: "textarea.tinymce",
          toolbar: ["undo redo | insert | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link | print preview | forecolor backcolor | codesample"],
          plugins: "link,advlist,codesample,autolink,lists,link,charmap,print,preview,hr,anchor,pagebreak,searchreplace,wordcount,visualblocks,visualchars,code,fullscreen,insertdatetime,nonbreaking,save,table,contextmenu,directionality,paste,textcolor,colorpicker,textpattern,imagetools,toc",
          codesample_languages: [{"text":"R","value":"r"},{"text":"MATLAB","value":"matlab"},{"text":"Python","value":"python"},{"text":"JSON","value":"javascript"},{"text":"HTML/XML","value":"markup"},{"text":"JavaScript","value":"javascript"},{"text":"CSS","value":"css"},{"text":"PHP","value":"php"},{"text":"Ruby","value":"ruby"},{"text":"Java","value":"java"},{"text":"C","value":"c"},{"text":"C#","value":"csharp"},{"text":"C++","value":"cpp"}],
          init_instance_callback: function(editor) {
            SmartAnnotation.init($(editor.contentDocument.activeElement));
          },
          setup: function(editor) {
            editor.on('keydown', function(e) {
              if(e.keyCode == 13 && $(editor.contentDocument.activeElement).atwho('isSelecting'))
                return false;
            });
          }
        });
      }
    },
    destroyAll: function() {
      _.each(tinymce.editors, function(editor) {
        editor.destroy();
        initHighlightjs();
      });
    },
    refresh: function() {
      this.destroyAll();
      this.init();
    },
    highlight: initHighlightjs
  });

})();
