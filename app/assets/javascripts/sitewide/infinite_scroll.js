/* eslint-disable no-use-before-define */
/* eslint-disable no-unused-vars */

var InfiniteScroll = (function() {
  function scrollNotVisible($container) {
    let eventTarget = $($container.data('config').eventTarget || $container);
    return scrollHitBottom(eventTarget[0]);
  }

  function loadData($container, page = 1) {
    var customParams = $container.data('config').customParams;
    var params = (customParams ? customParams({ page: page }) : { page: page });

    if ($container.hasClass('loading') || $container.hasClass('last-page')) return;
    $container.addClass('loading');
    renderPlaceholder($container);
    $.get($container.data('config').url, params, function(result) {
      $container.find('.placeholder-block').remove();
      if ($container.data('config').customResponse) {
        $container.data('config').customResponse(result, $container);
      } else {
        $(result.data).appendTo($container);
      }

      if (result.next_page) {
        $container.data('next-page', result.next_page);
      } else {
        $container.addClass('last-page');
        if ($container.data('config').endOfListTemplate && page >= 2) {
          $($($container.data('config').endOfListTemplate).html()).appendTo($container);
        }
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

    if (config.lastPage) {
      $container.addClass('last-page');
    }

    if (config.loadFirstPage) {
      loadData($container, 1);
    }

    let eventTarget = $($container.data('config').eventTarget || $container);
    eventTarget.on('scroll', () => {
      if (scrollHitBottom(eventTarget[0]) && !$container.hasClass('last-page')) {
        loadData($container, $container.data('next-page'));
      }
    });

    if (scrollNotVisible($container)) {
      loadData($container, $container.data('next-page'));
    }

    $(document).one('turbolinks:before-visit', $container.data('config').eventTarget, function() {
      removeScroll($container);
    });
  }

  // support functions

  // Full scroll height
  function scrollHeight(con) {
    return con.scrollHeight || document.documentElement.scrollHeight;
  }

  // Top scroll position
  function scrollTop(con) {
    return con.scrollTop || con.scrollY || 0;
  }

  // Get container size
  function containerSize(con) {
    return con.innerHeight || con.offsetHeight;
  }

  // Container position
  function containerPosition(con) {
    return scrollTop(con) + containerSize(con);
  }

  // Check when load next page
  function scrollHitBottom(con) {
    return scrollHeight(con) - containerPosition(con) <= 100;
  }

  function removeScroll(con) {
    let $container = $(con);

    if (!$container.data('config')) {
      return;
    }

    let eventTarget = $($container.data('config').eventTarget) || $container;
    $container.data('config', null);
    $container.data('next-page', null);
    $container.removeClass('last-page');
    eventTarget.off('scroll');
  }

  function renderPlaceholder($container) {
    let palceholder = '';
    $.each(Array($container.data('config').pageSize || 10), function() {
      palceholder += $($container.data('config').placeholderTemplate).html();
    });
    $(palceholder).addClass('placeholder-block').appendTo($container);
  }

  return {
    init: (object, config) => {
      removeScroll(object);
      initScroll(object, config);
    },
    removeScroll: (object) => {
      removeScroll(object);
    },
    loadMore: (object) => {
      let $container = $(object);
      if (scrollNotVisible($container)) {
        loadData($container, $container.data('next-page'));
      }
    }
  };
}());
