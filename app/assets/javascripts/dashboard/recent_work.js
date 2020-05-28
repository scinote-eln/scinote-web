/* global I18n PerfectSb*/
/* eslint-disable no-param-reassign */

var DasboardRecentWorkWidget = (function() {
  function renderRecentWorkItem(data, container) {
    $.each(data, (i, item) => {
      var recentWorkItem = $($('#recent-work-item-template').html());
      recentWorkItem.attr('href', item.url);
      recentWorkItem.find('.object-name').html(item.name);
      recentWorkItem.find('.object-type').html(I18n.t('dashboard.recent_work.subject_type.' + item.subject_type));
      recentWorkItem.find('.object-changed').html(item.last_change);
      container.append(recentWorkItem);
    });
  }

  function initRecentWork() {
    var container = $('.recent-work-container');
    $('.recent-work-container').empty();
    $.get(container.data('url'), {
      mode: $('.recent-work-navbar .active').data('mode')
    }, function(result) {
      if (result.length) {
        renderRecentWorkItem(result, container);
      } else {
        container.append($('#recent-work-no-results-template').html());
      }

      PerfectSb().update_all();
    });
  }

  function initNavbar() {
    $('.recent-work-navbar .navbar-link').on('click', function() {
      $(this).parent().find('.navbar-link').removeClass('active');
      $(this).addClass('active');
      initRecentWork();
    });
  }

  return {
    init: () => {
      if ($('.recent-work-widget').length) {
        initNavbar();
        initRecentWork();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  DasboardRecentWorkWidget.init();
});
