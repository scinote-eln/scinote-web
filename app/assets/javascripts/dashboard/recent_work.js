/* global I18n PerfectSb*/
/* eslint-disable no-param-reassign */

var DasboardRecentWorkWidget = (function() {
  function renderRecentWorkItem(data, container) {
    $.each(data, (i, item) => {
      var recentWorkItem = $($('#recent-work-item-template').html());
      var recentWorkItemType = recentWorkItem.find('.object-type span');
      recentWorkItem.attr('href', item.url);
      recentWorkItem.find('.object-name').html(item.name);
      recentWorkItemType.text(item.code || item.type);
      recentWorkItem.find('.object-changed').text(item.last_change);
      container.append(recentWorkItem);

      if (item.code) {
        recentWorkItemType.attr('data-toggle', 'tooltip');
        recentWorkItemType.attr('title', `${item.type} ID: ${item.code}`);
        recentWorkItemType.tooltip();
      }
      recentWorkItemType.attr('data-e2e', `e2e-TL-dashRecentWork-${item.type}`);
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
