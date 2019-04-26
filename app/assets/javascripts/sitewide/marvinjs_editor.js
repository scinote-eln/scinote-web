var MarvinJsEditor = (function() {

  var marvinJsModal = $('#MarvinJsModal');
  var marvinJsContainer = $('#marvinjs-editor');
  var marvinJsObject = $('#marvinjs-sketch');

  var loadEditor = () => {
    return MarvinJSUtil.getEditor('#marvinjs-sketch')
  }

  return Object.freeze({
    open: function(config) {
      MarvinJsEditor().reset()
      $(marvinJsModal).modal('show');
      $(marvinJsObject)
        .css('width', marvinJsContainer.width() + 'px')
        .css('height', marvinJsContainer.height() + 'px')

      marvinJsContainer[0].dataset.objectId = config.objectId;
      marvinJsContainer[0].dataset.objectType = config.objectType;
      marvinJsContainer[0].dataset.mode = config.mode;
      marvinJsModal.find('.file-save-link').off('click').on('click', () => {
        MarvinJsEditor().save()
      })

    },

    initNewButton: function(selector) {
      $(selector).off('click').on('click', function(){
        var objectId = this.dataset.objectId;
        var objectType = this.dataset.objectType;
        MarvinJsEditor().open({
          mode: 'new',
          objectId: objectId,
          objectType: objectType
        })
      })
    },

    save: function(){
      loadEditor().then(function(sketcherInstance) {
        sketcherInstance.exportStructure("mrv").then(function(source) {
          console.log(source);
        });
      })
    },

    reset: function(){
      marvinJsContainer[0].dataset.objectId = '';
      marvinJsContainer[0].dataset.objectType = '';
      marvinJsContainer[0].dataset.mode = '';
    }
  });
});
