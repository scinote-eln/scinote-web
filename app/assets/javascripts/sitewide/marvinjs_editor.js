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
    if (config.mode === 'new'){
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.importStructure("mrv",emptySketch)
        sketchName.val(I18n.t('marvinjs.new_sketch'))
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
  }

  return Object.freeze({
    open: function(config) {
      preloadActions(config)
      $(marvinJsModal).modal('show');
      $(marvinJsObject)
        .css('width', marvinJsContainer.width() + 'px')
        .css('height', marvinJsContainer.height() + 'px')
      marvinJsModal.find('.file-save-link').off('click').on('click', () => {
        MarvinJsEditor().save(config)
      })

    },

    initNewButton: function(selector) {
      $(selector).off('click').on('click', function(){
        var objectId = this.dataset.objectId;
        var objectType = this.dataset.objectType;
        var marvinUrl = this.dataset.marvinUrl;
        MarvinJsEditor().open({
          mode: 'new',
          objectId: objectId,
          objectType: objectType,
          marvinUrl: marvinUrl
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
            console.log(result)
            $(marvinJsModal).modal('hide');
          })
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
