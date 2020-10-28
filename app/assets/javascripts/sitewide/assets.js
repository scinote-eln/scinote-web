
$(document).on('click', '.asset .change-preview-type', function(e) {
  var viewMode = $(this).data('preview-type');
  var toggleUrl = $(this).data('toggle-view-url');
  var assetId = $(this).closest('.asset').data('asset-id');
  e.preventDefault();
  e.stopPropagation();
  $.ajax({
    url: toggleUrl,
    type: 'PATCH',
    dataType: 'json',
    data: { asset: { view_mode: viewMode } },
    success: function(data) {
      $(`.asset[data-asset-id=${assetId}]`).replaceWith(data.html);
    }
  });
});
