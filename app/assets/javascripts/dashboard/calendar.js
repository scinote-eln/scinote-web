/* global I18n */

var DasboardCalendarWidget = (function() {
  function calendarTemplate() {
    return `<script id="calendar-template" type="text/template">
              <div class="controls">
                <div class="clndr-previous-button">
                  <div class="btn btn-light icon-btn"><i class="fas fa-angle-double-left"></i></div>
                </div>
                <div class="clndr-title"><%= month %> <%= year %></div>
                <div class="clndr-next-button">
                  <div class="btn btn-light icon-btn"><i class="fas fa-angle-double-right"></i></div>
                </div>
              </div>
              <div class="days-container">
                <% _.each(daysOfTheWeek, function(day) { %>
                    <div class="day-header"><%= day %></div>
                <% }); %>
                <% _.each(days, function(day) { %>
                  <div class="<%= day.classes %>" id="<%= day.id %>"><%= day.day %></div>
                <% }); %>
              </div>
            </script>`;
  }

  function initCalendar() {
    var dayOfWeek = [
      I18n.t('dashboard.calendar.dow.su'),
      I18n.t('dashboard.calendar.dow.mo'),
      I18n.t('dashboard.calendar.dow.tu'),
      I18n.t('dashboard.calendar.dow.we'),
      I18n.t('dashboard.calendar.dow.th'),
      I18n.t('dashboard.calendar.dow.fr'),
      I18n.t('dashboard.calendar.dow.sa')
    ];
    $('.dashboard-calendar').clndr({
      template: $(calendarTemplate()).html(),
      adjacentDaysChangeMonth: true,
      daysOfTheWeek: dayOfWeek,
      forceSixRows: true
    });
  }


  return {
    init: () => {
      if ($('.current-tasks-widget').length) {
        initCalendar();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  DasboardCalendarWidget.init();
});
