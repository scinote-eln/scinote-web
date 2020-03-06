/* global I18n PerfectSb InfiniteScroll */
/* eslint-disable no-param-reassign */

var DasboardRecentWorkWidget = (function() {
  function initNavbar() {
    $('.recent-work-navbar .navbar-link').on('click', function() {
      $(this).parent().find('.navbar-link').removeClass('active');
      $(this).addClass('active');
      $('.recent-work-container').empty();
      InfiniteScroll.resetScroll('.recent-work-container');
      PerfectSb().update_all();
    });
  }

  function renderRecentWorkItem(json, container) {
    $.each(json.data, (i, item) => {
      var recentWorkItem = `<a href="${item.url}" class="recent-work-item">
                              <div class="object-name">${item.name}</div>
                              <div class="object-type">${I18n.t('dashboard.recent_work.subject_type.' + item.subject_type)}</div>
                              <div class="object-changed">${item.last_change}</div>
                            </a>`;
      $(container).append(recentWorkItem);
    });
  }

  function initRecentWork() {
    InfiniteScroll.init('.recent-work-container', {
      url: $('.recent-work-container').data('url'),
      loadFirstPage: true,
      customResponse: (json, container) => {
        renderRecentWorkItem(json, container);
      },
      customParams: (params) => {
        params.mode = $('.recent-work-navbar .active').data('mode');
        return params;
      },
      afterAction: (json, container) => {
        if (json.data.length === 0) {
          $(container).append(` <div class="no-results">
                                  <div class="no-results-title">${I18n.t('dashboard.recent_work.no_results.title')}</div>
                                  <div class="no-results-description">${I18n.t('dashboard.recent_work.no_results.description')}</div>
                                  <div class="no-results-arrow">
                                    <i class="fas fa-angle-double-left"></i>
                                  </div>
                                </div>`);
        }
      }
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
