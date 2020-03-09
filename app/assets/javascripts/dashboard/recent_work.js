/* global I18n PerfectSb*/
/* eslint-disable no-param-reassign */

var DasboardRecentWorkWidget = (function() {
  function renderRecentWorkItem(data, container) {
    $.each(data, (i, item) => {
      var recentWorkItem = `<a href="${item.url}" class="recent-work-item">
                              <div class="object-name">${item.name}</div>
                              <div class="object-type">${I18n.t('dashboard.recent_work.subject_type.' + item.subject_type)}</div>
                              <div class="object-changed">${item.last_change}</div>
                            </a>`;
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
        container.append(`<div class="no-results">
                            <div class="no-results-title">${I18n.t('dashboard.recent_work.no_results.title')}</div>
                            <div class="no-results-description">${I18n.t('dashboard.recent_work.no_results.description')}</div>
                            <div class="no-results-arrow">
                              <i class="fas fa-angle-double-left"></i>
                            </div>
                          </div>`);
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
