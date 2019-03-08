// Common code


Date.prototype.date_to_string = function() {
  return this.getFullYear() + '-' + (this.getMonth() + 1) + '-' + this.getDate();
};

// GA code

function GlobalActivitiesFiltersGetDates() {
  var fromDate = $('#calendar-from-date').data('DateTimePicker').date()._d.date_to_string();
  var toDate = $('#calendar-to-date').data('DateTimePicker').date()._d.date_to_string();
  return { from: fromDate, to: toDate };
}

function GlobalActivitiesFilterPrepareArray() {
  var teamFilter = ($('.ga-side .team-selector select').val() || [])
    .map(e => { return parseInt(e, 10); });
  var userFilter = ($('.ga-side .user-selector select').val() || [])
    .map(e => { return parseInt(e, 10); });
  var activityFilter = ($('.ga-side .activity-selector select').val() || [])
    .map(e => { return parseInt(e, 10); });
  var subjectFilter = {};
  $.each(($('.ga-side .subject-selector select').val() || []), function(index, object) {
    var splitObject = object.split('_');
    if (subjectFilter[splitObject[0]] === undefined) subjectFilter[splitObject[0]] = [];
    subjectFilter[splitObject[0]].push(parseInt(splitObject[1], 10));
  });
  return {
    teams: JSON.stringify(teamFilter),
    users: JSON.stringify(userFilter),
    types: JSON.stringify(activityFilter),
    subjects: JSON.stringify(subjectFilter),
    from_date: GlobalActivitiesFiltersGetDates().from,
    to_date: GlobalActivitiesFiltersGetDates().to
  };
}

function GlobalActivitiesUpdateTopPaneTags(event) {
  $('.ga-top .ga-tags').children().remove();

  $('<li class="select2-selection__choice">'
      + 'Activity created: '
      + $('.ga-side .date-selector.filter-block')[0].dataset.periodSelect
    + '</li>').appendTo('.ga-top .ga-tags');
  $.each($('.ga-side .select2-selection__choice'), function(index, tag) {
    var newTag = $(tag.outerHTML).appendTo('.ga-top .ga-tags');
    var selectedValues = [];
    var parentSelector = $(tag).parents('.select2-container').prev();
    var elementToDelete = null;
    newTag.find('.select2-selection__choice__remove')
      .click(() => {
        if (event && event.type === 'select2:select') {
          // Adding remove action for native blocks
          selectedValues = parentSelector.val();
          elementToDelete = $(tag).find('span.select2-block-body')[0].dataset.selectId;
          selectedValues = $.grep(selectedValues, v => { return v !== elementToDelete; });
          parentSelector.val(selectedValues).change();
        } else {
          $(tag).find('.select2-selection__choice__remove').click();
        }
      });
  });
}

$(function() {
  var selectors = ['team', 'activity', 'user'];
  // Ajax request for object search
  var subjectAjaxQuery = {
    url: '/global_activities/search_subjects',
    dataType: 'json',
    data: function(params) {
      return {
        query: params.term // search term
      };
    },
    // preparing results
    processResults: function(data) {
      var result = [];
      $.each(data, (key, items) => {
        var updateItems = items.map(item => {
          return {
            id: key + '_' + item.id,
            text: item.name,
            label: key
          };
        });
        result.push({ text: key, children: updateItems });
      });
      return {
        results: result
      };
    }
  };
  // custom display function
  var subjectCustomDisplay = (state) => {
    return state.label + ': ' + state.text;
  };
  // Common selection intialize
  $.each(selectors, (index, e) => {
    $('.ga-side .' + e + '-selector select').select2Multiple({ singleDisplay: true })
      .on('change', function() { GlobalActivitiesUpdateTopPaneTags(); });
    $('.ga-side .' + e + '-selector .clear').click(function() {
      $('.ga-side .' + e + '-selector select').select2MultipleClearAll();
    });
  });
  // Object selection intialize
  $('.ga-side .subject-selector select').select2Multiple({
    ajax: subjectAjaxQuery,
    customSelection: subjectCustomDisplay,
    unlimitedSize: true
  })
    .on('change select2:select', function(e) { GlobalActivitiesUpdateTopPaneTags(e); });
  $('.ga-side .subject-selector .clear').click(function() {
    $('.ga-side .subject-selector select').select2MultipleClearAll();
  });

  $('.ga-tags-container .clear-container span').click(function() {
    $.each(selectors, (index, e) => { $('.ga-side .' + e + '-selector select').select2MultipleClearAll(); });
    $('.ga-side .subject-selector select').select2MultipleClearAll();
  });

  $('#calendar-from-date').on('dp.change', function(e) {
    var dateContainer = $('.ga-side .date-selector.filter-block');
    $('#calendar-to-date').data('DateTimePicker').minDate(e.date);
    dateContainer[0].dataset.periodSelect = $('#calendar-from-date').val() + ' - ' + $('#calendar-to-date').val();
    GlobalActivitiesUpdateTopPaneTags();
  });

  $('#calendar-to-date').on('dp.change', function(e) {
    var dateContainer = $('.ga-side .date-selector.filter-block');
    $('#calendar-from-date').data('DateTimePicker').maxDate(e.date);
    dateContainer[0].dataset.periodSelect = $('#calendar-from-date').val() + ' - ' + $('#calendar-to-date').val();
    GlobalActivitiesUpdateTopPaneTags();
  });

  GlobalActivitiesUpdateTopPaneTags();
});

$('.date-selector .hot-button').click(function() {
  var selectPeriod = this.dataset.period;
  var dateContainer = $('.ga-side .date-selector.filter-block');
  var fromDate = $('#calendar-from-date').data('DateTimePicker');
  var toDate = $('#calendar-to-date').data('DateTimePicker');
  var today = new Date();
  var yesterday = new Date(new Date().setDate(today.getDate() - 1));
  var weekDay = today.getDay();
  var monday = new Date(new Date().setDate(today.getDate() - weekDay + (weekDay === 0 ? -6 : 1)));
  var sunday = new Date(new Date().setDate(new Date(monday).getDate() + 6));
  var lastWeek = new Date(new Date().setDate(today.getDate() - 6));
  var firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
  var lastDay = new Date(today.getFullYear(), today.getMonth() + 1, 0);
  var lastMonth = new Date(new Date().setDate(today.getDate() - 30));
  if (selectPeriod === 'today') {
    toDate.date(today);
    fromDate.date(today);
  } else if (selectPeriod === 'yesterday') {
    fromDate.date(yesterday);
    toDate.date(yesterday);
  } else if (selectPeriod === 'this_week') {
    toDate.date(sunday);
    fromDate.date(monday);
  } else if (selectPeriod === 'last_week') {
    toDate.date(today);
    fromDate.date(lastWeek);
  } else if (selectPeriod === 'this_month') {
    toDate.date(lastDay);
    fromDate.date(firstDay);
  } else if (selectPeriod === 'last_month') {
    toDate.date(today);
    fromDate.date(lastMonth);
  }
  dateContainer[0].dataset.periodSelect = this.innerHTML;
  GlobalActivitiesUpdateTopPaneTags();
});