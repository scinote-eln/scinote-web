(function () {
  'use strict';

  function initSwapRemoteContainerListeners() {
    $(document).on('click', 'a[data-action="swap-remote-container"]', function(el) {
      let element = el.target;
      el.stopPropagation();
      el.preventDefault();

      $.get(element.getAttribute('href')).then(function({html}) {
        let target = element.getAttribute('data-target')
        document.getElementById(target).insertAdjacentHTML(html)
      })
    })
  }

  $(document).on('turbolinks:load', initSwapRemoteContainerListeners);
})();
