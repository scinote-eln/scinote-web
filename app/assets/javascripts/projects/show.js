(function() {
  function init() {
    $('.workflowimg-container').each(function() {
      let container = $(this);
      if (container.data('workflowimg-present') === false) {
        let imgUrl = container.data('workflowimg-url');
        container.find('.workflowimg-spinner').removeClass('hidden');
        $.ajax({
          url: imgUrl,
          type: 'GET',
          dataType: 'json',
          success: function(data) {
            container.html(data.workflowimg);
          },
          error: function() {
            container.find('.workflowimg-spinner').addClass('hidden');
          }
        });
      }
    });
  }

  init();
}());
