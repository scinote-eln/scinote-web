var MarvinJsEditor = (function() {

  var marvinJsModal = $('#MarvinJsModal');
  var marvinJsContainer = $('#marvinjs-editor');
  var marvinJsObject = $('#marvinjs-sketch');
  var emptySketch = "<cml><MDocument></MDocument></cml>"
  var sketchName = marvinJsModal.find('.file-name input')

  var loadEditor = () => {
    return MarvinJSUtil.getEditor('#marvinjs-sketch')
  }

  var loadPackages = () => {
    return MarvinJSUtil.getPackage('#marvinjs-sketch')
  }

  function preloadActions(config) {
    if (config.mode === 'new' || config.mode === 'new-tinymce'){
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.importStructure("mrv",emptySketch)
        sketchName.val(I18n.t('marvinjs.new_sketch'))
      })
    }else if (config.mode === 'edit'){
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.importStructure("mrv",config.data)
        sketchName.val(config.name)
      })
    }
  }

  function createExporter(marvin,imageType) {
    var inputFormat = "mrv";
    var settings = {
      'width' : 900,
      'height' : 900
    };

    var params = {
      'imageType': imageType,
      'settings': settings,
      'inputFormat': inputFormat
    }
    return new marvin.ImageExporter(params);
  }

  function assignImage(target,data){
    target.attr('src',data)
    return data
  }

  function TinyMceBuildHTML(json) {
    var imgstr = "<img src='" + json.image.url + "'";
    imgstr += " data-mce-token='" + json.image.token + "'";
    imgstr += " alt='description-" + json.image.token + "' />";
    return imgstr;
  }

  return Object.freeze({
    open: function(config) {
      preloadActions(config)
      $(marvinJsModal).modal('show');
      $(marvinJsObject)
        .css('width', marvinJsContainer.width() + 'px')
        .css('height', marvinJsContainer.height() + 'px')
      marvinJsModal.find('.file-save-link').off('click').on('click', () => {
        if (config.mode === 'new'){
          MarvinJsEditor().save(config)
        } else if (config.mode === 'edit'){
          MarvinJsEditor().update(config)
        } else if (config.mode === 'new-tinymce'){
          config.objectType = 'TinyMceAsset'
          MarvinJsEditor().save_with_image(config)
        }
      })

    },

    initNewButton: function(selector) {
      $(selector).off('click').on('click', function(){
        var objectId = this.dataset.objectId;
        var objectType = this.dataset.objectType;
        var marvinUrl = this.dataset.marvinUrl;
        var container = this.dataset.sketchContainer
        MarvinJsEditor().open({
          mode: 'new',
          objectId: objectId,
          objectType: objectType,
          marvinUrl: marvinUrl,
          container: container
        })
      })
    },

    save: function(config){
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.exportStructure("mrv").then(function(source) {
          $.post(config.marvinUrl,{
            description: source,
            object_id: config.objectId,
            object_type: config.objectType,
            name: sketchName.val()
          }, function(result){
            if (config.objectType === 'Step'){
              new_asset = $(result.html)
              new_asset.find('.file-preview-link').css('top','-300px')
              new_asset.addClass('new').prependTo($(config.container))
              setTimeout(function(){
                new_asset.find('.file-preview-link').css('top','0px')
              },200)
              FilePreviewModal.init()
            }
            $(marvinJsModal).modal('hide');
          })
        });
      })
    },

    save_with_image: function(config){
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.exportStructure("mrv").then(function(mrv_description) {
          loadPackages().then(function (sketcherPackage) {
            sketcherPackage.onReady(function() {
              exporter = createExporter(sketcherPackage,'image/jpeg')
              exporter.render(mrv_description).then(function(image){
                $.post(config.marvinUrl,{
                  description: mrv_description,
                  object_id: config.objectId,
                  object_type: config.objectType,
                  name: sketchName.val(),
                  image: image
                }, function(result){
                  var json = tinymce.util.JSON.parse(result);
                  config.editor.execCommand('mceInsertContent', false, TinyMceBuildHTML(json));
                  TinyMCE.updateImages(config.editor)
                  $(marvinJsModal).modal('hide');
                })
              });
            });
          });
        });
      })
    },

    update: function(config){
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.exportStructure("mrv").then(function(source) {
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
              config.reloadImage.src.val(json.description)
              $(config.reloadImage.sketch).find('.attachment-label').text(json.name)
              MarvinJsEditor().create_preview(
                config.reloadImage.src, 
                $(config.reloadImage.sketch).find('img')
              )
            }
          });
        });
      })
    },

    create_preview: function(source,target){
      loadPackages().then(function (sketcherInstance) {
        sketcherInstance.onReady(function() {
          exporter = createExporter(sketcherInstance,'image/jpeg')
          sketch_config = source.val();
          exporter.render(sketch_config).then(function(result){
            assignImage(target,result)
          });
        });
      });
    },

    create_download_link: function(source,link,filename){
      loadPackages().then(function (sketcherInstance) {
        sketcherInstance.onReady(function() {
          exporter = createExporter(sketcherInstance,'image/jpeg')
          sketch_config = source.val();
          exporter.render(sketch_config).then(function(result){
            link.attr('href', result);
            link.attr('download', filename);
          });
        });
      });
    },

    delete_sketch: function(url,object){
      $.ajax({
        url: url,
        dataType: 'json',
        type: 'DELETE',
        success: function(json) {
          $(object).remove()
        }
      });
    }
  });
});

(function() {
  'use strict';

  tinymce.PluginManager.requireLangPack('MarvinJsPlugin');

  tinymce.create('tinymce.plugins.MarvinJsPlugin', {
    MarvinJsPlugin: function(ed, url) {
      var editor = ed;

      function openMarvinJs(){
        MarvinJsEditor().open({
          mode: 'new-tinymce',
          marvinUrl: '/marvin_js_assets',
          editor: editor
        })
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
