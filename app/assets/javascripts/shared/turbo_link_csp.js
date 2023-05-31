document.addEventListener('turbolinks:request-start', function(event) {
  var xhr = event.data.xhr;
  xhr.setRequestHeader('X-Turbolinks-Nonce', $('meta[name="csp-nonce"]').prop('content'));
});

document.addEventListener('turbolinks:before-cache', function() {
  $('script[nonce]').each(function(_index, element) {
    $(element).attr('nonce', element.nonce);
  });
});
