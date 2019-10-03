/* global TinyMCE, ChemicalizeMarvinJs, MarvinJSUtil, I18n, FilePreviewModal, tinymce */
/* global Results, Comments */
/* eslint-disable no-param-reassign */
/* eslint-disable wrap-iife */
/* eslint-disable no-use-before-define */


var marvinJsRemoteLastMrv;
var marvinJsRemoteEditor;
var MarvinJsEditor;

var MarvinJsEditorApi = (function() {
  var marvinJsModal = $('#MarvinJsModal');
  var marvinJsContainer = $('#marvinjs-editor');
  var marvinJsObject = $('#marvinjs-sketch');
  var emptySketch = '<cml><MDocument></MDocument></cml>';
  var sketchName = marvinJsModal.find('.file-name input');
  var marvinJsMode = marvinJsContainer.data('marvinjsMode');

  // Facade api actions
  var marvinJsExportImage = (childFuction, options = {}) => {
    if (marvinJsMode === 'remote') {
      remoteExportImage(childFuction, options);
    } else {
      localExportImage(childFuction, options);
    }
  };
  // ///////////////

  var loadEditor = () => {
    if (marvinJsMode === 'remote') {
      return marvinJsRemoteEditor;
    }
    return MarvinJSUtil.getEditor('#marvinjs-sketch');
  };
  var loadPackages = () => {
    return MarvinJSUtil.getPackage('#marvinjs-sketch');
  };

  // Local marvinJS installation

  var localExportImage = (childFuction, options = {}) => {
    loadEditor().then(function(sketcherInstance) {
      sketcherInstance.exportStructure('mrv').then(function(source) {
        loadPackages().then(function(sketcherPackage) {
          sketcherPackage.onReady(function() {
            var exporter = createExporter(sketcherPackage, 'image/jpeg');
            exporter.render(source).then(function(image) {
              childFuction(source, image, options);
            });
          });
        });
      });
    });
  };

  // Web services installation

  var remoteImage = (childFuction, source, options = {}) => {
    var params = {
      carbonLabelVisible: false,
      implicitHydrogen: 'TERMINAL_AND_HETERO',
      displayMode: 'WIREFRAME',
      width: 900,
      height: 900
    };
    if (typeof (marvinJsRemoteEditor) === 'undefined') {
      setTimeout(() => { remoteImage(childFuction, source, options); }, 100);
      return false;
    }
    marvinJsRemoteEditor.exportMrvToImageDataUri(source, 'image/jpeg', params).then(function(image) {
      childFuction(source, image, options);
    });
    return true;
  };

  var remoteExportImage = (childFuction, options = {}) => {
    remoteImage(childFuction, marvinJsRemoteLastMrv, options);
  };

  // Support actions
  function preloadActions(config) {
    if (marvinJsMode === 'remote') {
      if (config.mode === 'new' || config.mode === 'new-tinymce') {
        marvinJsRemoteEditor.importStructure('mrv', emptySketch);
        sketchName.val('');
      } else if (config.mode === 'edit') {
        marvinJsRemoteLastMrv = config.data;
        marvinJsRemoteEditor.importStructure('mrv', config.data);
        sketchName.val(config.name);
      } else if (config.mode === 'edit-tinymce') {
        marvinJsRemoteLastMrv = config.data;
        $.get(config.marvinUrl, { object_type: 'TinyMceAsset', show_action: 'start_edit' }, function(result) {
          marvinJsRemoteEditor.importStructure('mrv', result.description);
          sketchName.val(result.name);
        });
      }
      marvinJsRemoteEditor.on('molchange', () => {
        marvinJsRemoteEditor.exportStructure('mrv').then(function(source) {
          marvinJsRemoteLastMrv = source;
        });
      });
    } else {
      loadEditor().then(function(marvin) {
        if (config.mode === 'new' || config.mode === 'new-tinymce') {
          marvin.importStructure('mrv', emptySketch);
          sketchName.val(I18n.t('marvinjs.new_sketch'));
        } else if (config.mode === 'edit') {
          marvin.importStructure('mrv', config.data);
          sketchName.val(config.name);
        } else if (config.mode === 'edit-tinymce') {
          $.get(config.marvinUrl, { object_type: 'TinyMceAsset', show_action: 'start_edit' }, function(result) {
            marvin.importStructure('mrv', result.description);
            sketchName.val(result.name);
          });
        }
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

  function TinyMceBuildHTML(json) {
    var imgstr = "<img src='" + json.image.url + "'";
    imgstr += " width='300' height='300'";
    imgstr += " data-mce-token='" + json.image.token + "'";
    imgstr += " data-source-type='" + json.image.source_type + "'";
    imgstr += " alt='description-" + json.image.token + "' />";
    return imgstr;
  }

  function saveFunction(source, image, config) {
    $.post(config.marvinUrl, {
      description: source,
      object_id: config.objectId,
      object_type: config.objectType,
      name: sketchName.val(),
      image: image
    }, function(result) {
      var newAsset = $(result.html);
      var json;
      if (config.objectType === 'Step') {
        newAsset.find('.file-preview-link').css('top', '-300px');
        newAsset.addClass('new').prependTo($(config.container));
        setTimeout(function() {
          newAsset.find('.file-preview-link').css('top', '0px');
        }, 200);
      } else if (config.objectType === 'Result') {
        newAsset.prependTo($(config.container));
        Results.expandResult(newAsset);
        Comments.init();
      } else if (config.objectType === 'TinyMceAsset') {
        json = tinymce.util.JSON.parse(result);
        config.editor.execCommand('mceInsertContent', false, TinyMceBuildHTML(json));
        TinyMCE.updateImages(config.editor);
      }
      $(marvinJsModal).modal('hide');
      FilePreviewModal.init();
      config.button.dataset.inProgress = false;
    });
  }

  function updateFunction(source, image, config) {
    $.ajax({
      url: config.marvinUrl,
      data: {
        description: source,
        name: sketchName.val(),
        object_type: config.objectType,
        image: image
      },
      dataType: 'json',
      type: 'PUT',
      success: function(json) {
        if (config.objectType === 'TinyMceAsset') {
          TinyMCE.makeItDirty(config.editor);
          config.image[0].src = json.url;
          config.image[0].dataset.mceSrc = json.url;
          $(`img[data-mce-token=${config.image[0].dataset.mceToken}]`)
            .attr('src', json.url);
        } else {
          $('#modal_link' + json.id + ' img').attr('src', json.url);
          $('#modal_link' + json.id + ' img').css('opacity', '0');
          $('#modal_link' + json.id + ' .attachment-label').html(json.file_name);
        }
        $(marvinJsModal).modal('hide');
        config.button.dataset.inProgress = false;
      }
    });
  }

  // MarvinJS Methods

  return {
    enabled: function() {
      return ($('#MarvinJsModal').length > 0);
    },

    open: function(config) {
      if (!MarvinJsEditor.enabled()) {
        $('#MarvinJsPromoModal').modal('show');
        return false;
      }
      if (marvinJsMode === 'remote' && typeof (marvinJsRemoteEditor) === 'undefined') {
        setTimeout(() => { MarvinJsEditor.open(config); }, 100);
        return false;
      }
      preloadActions(config);
      $(marvinJsModal).modal('show');
      $(marvinJsObject)
        .css('width', marvinJsContainer.width() + 'px')
        .css('height', marvinJsContainer.height() + 'px');
      marvinJsModal.find('.file-save-link').off('click').on('click', function() {
        if (this.dataset.inProgress === 'true') return;

        this.dataset.inProgress = true;
        config.button = this;
        if (config.mode === 'new') {
          MarvinJsEditor.save(config);
        } else if (config.mode === 'edit') {
          config.objectType = 'Asset';
          MarvinJsEditor.update(config);
        } else if (config.mode === 'new-tinymce') {
          config.objectType = 'TinyMceAsset';
          MarvinJsEditor.save(config);
        } else if (config.mode === 'edit-tinymce') {
          config.objectType = 'TinyMceAsset';
          MarvinJsEditor.update(config);
        }
      });
      return true;
    },

    initNewButton: function(selector) {
      $(selector).off('click').on('click', function() {
        var objectId = this.dataset.objectId;
        var objectType = this.dataset.objectType;
        var marvinUrl = this.dataset.marvinUrl;
        var container = this.dataset.sketchContainer;
        MarvinJsEditor.open({
          mode: 'new',
          objectId: objectId,
          objectType: objectType,
          marvinUrl: marvinUrl,
          container: container
        });
      });
    },

    save: function(config) {
      marvinJsExportImage(saveFunction, config);
    },

    update: function(config) {
      marvinJsExportImage(updateFunction, config);
    }
  };
});

// TinyMCE plugin

(function() {
  'use strict';

  tinymce.PluginManager.requireLangPack('MarvinJsPlugin');

  tinymce.create('tinymce.plugins.MarvinJsPlugin', {
    MarvinJsPlugin: function(ed) {
      var editor = ed;

      function openMarvinJs() {
        MarvinJsEditor.open({
          mode: 'new-tinymce',
          marvinUrl: '/tiny_mce_assets/marvinjs',
          editor: editor
        });
      }
      // Add a button that opens a window
      editor.addButton('marvinjsplugin', {
        tooltip: I18n.t('marvinjs.new_button'),
        icon: 'marvinjs',
        onclick: openMarvinJs
      });

      // Adds a menu item to the tools menu
      editor.addMenuItem('marvinjsplugin', {
        text: I18n.t('marvinjs.new_button'),
        icon: 'marvinjs',
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

// Initialization


$(document).on('turbolinks:load', function() {
  MarvinJsEditor = MarvinJsEditorApi();
  if (MarvinJsEditor.enabled()) {
    if ($('#marvinjs-editor')[0].dataset.marvinjsMode === 'remote') {
      ChemicalizeMarvinJs.createEditor('#marvinjs-sketch').then(function(marvin) {
        marvin.setDisplaySettings({ toolbars: 'reporting' });
        marvinJsRemoteEditor = marvin;
      });
    }
  }
  MarvinJsEditor.initNewButton('.new-marvinjs-upload-button');
});
