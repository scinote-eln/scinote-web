/* eslint-disable no-param-reassign */

var DasboardQuickStartWidget = (function() {
  function initNewReportLink() {
    $('.quick-start-buttons .new-report').click(() => {
      sessionStorage.setItem('scinote-dashboard-new-report', Math.floor(Date.now() / 1000));
    });
  }

  function initNewProtocolLink() {
    $('.quick-start-buttons .new-protocol').click(() => {
      sessionStorage.setItem('scinote-dashboard-new-protocol', Math.floor(Date.now() / 1000));
    });
  }

  return {
    init: () => {
      if ($('.quick-start-buttons').length) {
        initNewProtocolLink();
        initNewReportLink();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  DasboardQuickStartWidget.init();
});
