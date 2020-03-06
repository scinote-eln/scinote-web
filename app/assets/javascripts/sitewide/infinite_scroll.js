/* eslint-disable no-unused-vars */

var InfiniteScroll = (function() {
  function getScrollHeight($container) {
    return $container[0].scrollHeight;
  }

  function scrollNotVisible($container) {
    return (getScrollHeight($container) - $container.height() - 150 <= 0);
  }

  function loadData($container, page = 1) {
    var customParams = $container.data('config').customParams;
    var params = (customParams ? customParams({ page: page }) : { page: page });

    if ($container.hasClass('loading') || $container.hasClass('last-page')) return;
    $container.addClass('loading');

    $.get($container.data('config').url, params, function(result) {
      if ($container.data('config').customResponse) {
        $container.data('config').customResponse(result, $container);
      } else {
        $(result.data).appendTo($container);
      }

      if (result.next_page) {
        $container.data('next-page', result.next_page);
      } else {
        $container.addClass('last-page');
      }
      $container.removeClass('loading');

      if ($container.data('config').afterAction) {
        $container.data('config').afterAction(result, $container);
      }

      if (scrollNotVisible($container)) {
        loadData($container, $container.data('next-page'));
      }
    });
  }

  function initScroll(object, config = {}) {
    var $container = $(object);
    $container.data('next-page', 2);
    $container.data('config', config);

    if (config.loadFirstPage) {
      loadData($container, 1);
    } else if (scrollNotVisible($container)) {
      loadData($container, $container.data('next-page'));
    }

    $container.on('scroll', () => {
      if ($container.scrollTop() + $container.height() > getScrollHeight($container) - 150 && !$container.hasClass('last-page')) {
        loadData($container, $container.data('next-page'));
      }
    });
  }

  return {
    init: (object, config) => {
      initScroll(object, config);
    },
    resetScroll: (object) => {
      $(object).data('next-page', $(object).data('config').loadFirstPage ? 1 : 2).removeClass('last-page');
      if (scrollNotVisible($(object))) {
        loadData($(object), $(object).data('next-page'));
      }
    }
  };
}());
