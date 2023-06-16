/* global I18n */
/* eslint-disable no-underscore-dangle */

var DasboardCalendarWidget = (function() {
  function calendarTemplate() {
    return `<script id="calendar-template" type="text/template">
              <div class="controls">
                <div class="clndr-previous-button">
                  <div class="btn btn-light icon-btn"><i class="sn-icon sn-icon-left"></i></div>
                </div>
                <div class="clndr-title"><%= month %> <%= year %></div>
                <div class="clndr-next-button">
                  <div class="btn btn-light icon-btn"><i class="sn-icon sn-icon sn-icon-right"></i></div>
                </div>
              </div>
              <div class="days-container">
                <% _.each(daysOfTheWeek, function(day) { %>
                    <div class="day-header"><%= day %></div>
                <% }); %>
                <% _.each(days, function(day) { %>
                  <% if (day.classes.includes('event')){ %>
                    <div class="<%= day.classes %> dropdown" id="<%= day.id %>">
                      <div class="event-day" data-toggle="dropdown"><%= day.day %></div>
                      <div class="dropdown-menu events-container dropdown-menu-right" role="menu">
                        <div class="title">${I18n.t('dashboard.calendar.due_on')} <%= day.date.format(formatJS) %></div>
                        <div class="tasks"></div>
                      </div>
                    </div>
                  <% } else { %>
                    <div class="<%= day.classes %>" id="<%= day.id %>"><%= day.day %></div>
                  <% } %>
                <% }); %>
              </div>
            </script>`;
  }

  function getMonthEventsList(date, clndrInstance) {
    var getUrl = $('.dashboard-calendar').data('month-events-url');
    $.get(getUrl, { date: date }, function(result) {
      clndrInstance.setEvents(result.events);
    });
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
    var clndrInstance = $('.dashboard-calendar').clndr({
      template: $(calendarTemplate()).html(),
      daysOfTheWeek: dayOfWeek,
      forceSixRows: true,
      clickEvents: {
        click: function(target) {
          var getDayUrl = $('.dashboard-calendar').data('day-events-url');
          if ($(target.element).hasClass('event')) {
            $.get(getDayUrl, { date: target.date._i }, function(result) {
              $(target.element).find('.tasks').html(result.html);
            });
          }
        },
        onMonthChange: function(month) {
          getMonthEventsList(month._d, clndrInstance);
        }
      }
    });

    getMonthEventsList((new Date()), clndrInstance);
  }


  return {
    init: () => {
      if ($('.current-tasks-widget').length) {
        initCalendar();
      }
    }
  };
}());

var formatJS;
$(document).on('turbolinks:load', function() {
  DasboardCalendarWidget.init();
  formatJS = $('body').data('datetime-picker-format');
});
