$(document).on('turbolinks:load', function() {
  $(document).on('click', '#revokeDeviceBtn', function() {
    $('#deviceRevocationModal').modal('show');
  });
});
