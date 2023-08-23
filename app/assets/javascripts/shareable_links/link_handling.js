(function() {
  $(document).off('click', 'a[rel*=external]').on('click', 'a[rel*=external]', function(e) {
    e.preventDefault();
    window.open(this.href, '_blank', 'noopener');
  });
}());
