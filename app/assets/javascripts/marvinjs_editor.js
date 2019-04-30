/* global MarvinJSUtil, I18n, FilePreviewModal, tinymce, TinyMCE PerfectScrollbar */
/* eslint-disable no-param-reassign */
/* eslint-disable wrap-iife */

var MarvinJsEditor = (function() {
  var marvinJsModal = $('#MarvinJsModal');
  var marvinJsContainer = $('#marvinjs-editor');
  var marvinJsObject = $('#marvinjs-sketch');
  var emptySketch = '<cml><MDocument></MDocument></cml>';
  var sketchName = marvinJsModal.find('.file-name input');

  var loadEditor = () => {
    return MarvinJSUtil.getEditor('#marvinjs-sketch');
  };

  var loadPackages = () => {
    return MarvinJSUtil.getPackage('#marvinjs-sketch');
  };

  function preloadActions(config) {
    if (config.mode === 'new' || config.mode === 'new-tinymce') {
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.importStructure('mrv', emptySketch);
        sketchName.val(I18n.t('marvinjs.new_sketch'));
      });
    } else if (config.mode === 'edit') {
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.importStructure('mrv', config.data);
        sketchName.val(config.name);
      });
    } else if (config.mode === 'edit-tinymce') {
      loadEditor().then(function(sketcherInstance) {
        $.get(config.marvinUrl, function(result) {
          sketcherInstance.importStructure('mrv', result.description);
          sketchName.val(result.name);
        });
      });
    }
  }

  function createExporter(marvin, imageType) {
    var inputFormat = 'mrv';
    var settings = {
      width: 900,
      height: 900
    };

    var params = {
      imageType: imageType,
      settings: settings,
      inputFormat: inputFormat
    };
    return new marvin.ImageExporter(params);
  }

  function assignImage(target, data) {
    target.attr('src', data);
    return data;
  }

  function TinyMceBuildHTML(json) {
    var imgstr = "<img src='" + json.image.url + "'";
    imgstr += " data-mce-token='" + json.image.token + "'";
    imgstr += " data-source-id='" + json.image.source_id + "'";
    imgstr += " data-source-type='" + json.image.source_type + "'";
    imgstr += " alt='description-" + json.image.token + "' />";
    return imgstr;
  }

  return Object.freeze({
    open: function(config) {
      MarvinJsEditor().team_sketches();
      preloadActions(config);
      $(marvinJsModal).modal('show');
      $(marvinJsObject)
        .css('width', (marvinJsContainer.width() - 200) + 'px')
        .css('height', marvinJsContainer.height() + 'px');
      marvinJsModal.find('.file-save-link').off('click').on('click', () => {
        if (config.mode === 'new') {
          MarvinJsEditor().save(config);
        } else if (config.mode === 'edit') {
          MarvinJsEditor().update(config);
        } else if (config.mode === 'new-tinymce') {
          config.objectType = 'TinyMceAsset';
          MarvinJsEditor().save_with_image(config);
        } else if (config.mode === 'edit-tinymce') {
          MarvinJsEditor().update_tinymce(config);
        }
      });
    },

    initNewButton: function(selector) {
      $(selector).off('click').on('click', function() {
        var objectId = this.dataset.objectId;
        var objectType = this.dataset.objectType;
        var marvinUrl = this.dataset.marvinUrl;
        var container = this.dataset.sketchContainer;
        MarvinJsEditor().open({
          mode: 'new',
          objectId: objectId,
          objectType: objectType,
          marvinUrl: marvinUrl,
          container: container
        });
      });
    },

    save: function(config) {
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.exportStructure('mrv').then(function(source) {
          $.post(config.marvinUrl, {
            description: source,
            object_id: config.objectId,
            object_type: config.objectType,
            name: sketchName.val()
          }, function(result) {
            var newAsset;
            if (config.objectType === 'Step') {
              newAsset = $(result.html);
              newAsset.find('.file-preview-link').css('top', '-300px');
              newAsset.addClass('new').prependTo($(config.container));
              setTimeout(function() {
                newAsset.find('.file-preview-link').css('top', '0px');
              }, 200);
              FilePreviewModal.init();
            }
            $(marvinJsModal).modal('hide');
          });
        });
      });
    },

    save_with_image: function(config) {
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.exportStructure('mrv').then(function(mrvDescription) {
          loadPackages().then(function(sketcherPackage) {
            sketcherPackage.onReady(function() {
              var exporter = createExporter(sketcherPackage, 'image/jpeg');
              exporter.render(mrvDescription).then(function(image) {
                $.post(config.marvinUrl, {
                  description: mrvDescription,
                  object_id: config.objectId,
                  object_type: config.objectType,
                  name: sketchName.val(),
                  image: image
                }, function(result) {
                  var json = tinymce.util.JSON.parse(result);
                  config.editor.execCommand('mceInsertContent', false, TinyMceBuildHTML(json));
                  TinyMCE.updateImages(config.editor);
                  $(marvinJsModal).modal('hide');
                });
              });
            });
          });
        });
      });
    },

    update: function(config) {
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.exportStructure('mrv').then(function(source) {
          $.ajax({
            url: config.marvinUrl,
            data: {
              description: source,
              name: sketchName.val()
            },
            dataType: 'json',
            type: 'PUT',
            success: function(json) {
              $(marvinJsModal).modal('hide');
              config.reloadImage.src.val(json.description);
              $(config.reloadImage.sketch).find('.attachment-label').text(json.name);
              MarvinJsEditor().create_preview(
                config.reloadImage.src,
                $(config.reloadImage.sketch).find('img')
              );
            }
          });
        });
      });
    },

    update_tinymce: function(config) {
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.exportStructure('mrv').then(function(mrvDescription) {
          loadPackages().then(function(sketcherPackage) {
            sketcherPackage.onReady(function() {
              var exporter = createExporter(sketcherPackage, 'image/jpeg');
              exporter.render(mrvDescription).then(function(image) {
                $.ajax({
                  url: config.marvinUrl,
                  data: {
                    description: mrvDescription,
                    name: sketchName.val(),
                    object_type: 'TinyMceAsset',
                    image: image
                  },
                  dataType: 'json',
                  type: 'PUT',
                  success: function(json) {
                    config.image[0].src = json.url;
                    config.saveButton.removeClass('hidden');
                    $(marvinJsModal).modal('hide');
                  }
                });
              });
            });
          });
        });
      });
    },

    create_preview: function(source, target) {
      loadPackages().then(function(sketcherInstance) {
        sketcherInstance.onReady(function() {
          var exporter = createExporter(sketcherInstance, 'image/jpeg');
          var sketchConfig = source.val();
          exporter.render(sketchConfig).then(function(result) {
            assignImage(target, result);
          });
        });
      });
    },

    create_download_link: function(source, link, filename) {
      loadPackages().then(function(sketcherInstance) {
        sketcherInstance.onReady(function() {
          var exporter = createExporter(sketcherInstance, 'image/jpeg');
          var sketchConfig = source.val();
          exporter.render(sketchConfig).then(function(result) {
            link.attr('href', result);
            link.attr('download', filename);
          });
        });
      });
    },

    delete_sketch: function(url, object) {
      $.ajax({
        url: url,
        dataType: 'json',
        type: 'DELETE',
        success: function() {
          $(object).remove();
        }
      });
    },

    team_sketches: function() {
      var ps = new PerfectScrollbar(marvinJsContainer.find('.marvinjs-team-sketch')[0]);
      marvinJsContainer.find('.sketch-container').remove();
      $.get('/marvin_js_assets/team_sketches', function(result) {
        $(result.html).appendTo(marvinJsContainer.find('.marvinjs-team-sketch'));

        $.each(result.sketches, function(i, sketch) {
          var sketchObj = marvinJsContainer.find('.marvinjs-team-sketch .sketch-container[data-sketch-id="' + sketch + '"]');
          var src = sketchObj.find('#description');
          var dest = sketchObj.find('img');
          MarvinJsEditor().create_preview(src, dest);
          setTimeout(() => { ps.update(); }, 500);
          marvinJsContainer.find('.sketch-container').click(function() {
            var sketchContainer = $(this);
            loadEditor().then(function(sketcherInstance) {
              sketcherInstance.importStructure('mrv', sketchContainer.find('#description').val());
            });
          });
        });
      });
    }
  });
});

(function() {
  'use strict';

  tinymce.PluginManager.requireLangPack('MarvinJsPlugin');

  tinymce.create('tinymce.plugins.MarvinJsPlugin', {
    MarvinJsPlugin: function(ed) {
      var editor = ed;

      function openMarvinJs() {
        MarvinJsEditor().open({
          mode: 'new-tinymce',
          marvinUrl: '/marvin_js_assets',
          editor: editor
        });
      }
      // Add a button that opens a window
      editor.addButton('marvinjsplugin', {
        tooltip: I18n.t('marvinjs.new_button'),
        icon: 'file-invoice',
        onclick: openMarvinJs
      });

      // Adds a menu item to the tools menu
      editor.addMenuItem('marvinjsplugin', {
        text: I18n.t('marvinjs.new_button'),
        icon: 'file-invoice',
        context: 'insert',
        onclick: openMarvinJs
      });
    }
  });

  tinymce.PluginManager.add(
    'marvinjsplugin',
    tinymce.plugins.MarvinJsPlugin
  );
})();
