<template>
  <div class="calendar-view w-full">
    <ScheduleXCalendar v-if="calendarApp" :calendar-app="calendarApp" class="w-full h-full" />
  </div>
</template>

<script>
  import axios from '../../packs/custom_axios.js';
  import { ScheduleXCalendar } from '@schedule-x/vue'
  import {
    createCalendar,
    createViewDay,
    createViewMonthGrid,
    createViewWeek,
  } from '@schedule-x/calendar'
  import { createEventsServicePlugin } from '@schedule-x/events-service'

  import 'temporal-polyfill/global'
  import {
    calendar_events_path
  } from '../../routes.js';

  const eventsServicePlugin = createEventsServicePlugin();
  let calendarApp = null;

  const calendarsVariants = {
    calibration: {
      colorName: 'calibration',
      lightColors: {
        main: '#E9A845',
        container: '#fff0d2',
        onContainer: '#4a2b00',
      },
    },
    maintenance: {
      colorName: 'maintenance',
      lightColors: {
        main: '#DF3562',
        container: '#ffe0e8',
        onContainer: '#4d0017',
      },
    },
    usage: {
      colorName: 'usage',
      lightColors: {
        main: '#3B99FD',
        container: '#d2e7ff',
        onContainer: '#002859',
      }
    },
    no_type: {
      colorName: 'no_type',
      lightColors: {
        main: '#6F2DC1',
        container: '#f0d2ff',
        onContainer: '#2b004a',
      }
    },
  }

  export default {
    name: 'CalendarView',
    props: {
      repositoryId: {
        type: Number,
        required: true
      },
      filters: {
        type: Object,
        required: true
      }
    },
    computed: {
      calendarApp() {
        return calendarApp;
      },
      eventsUrl() {
        return calendar_events_path();
      }
    },
    created() {
      const component = this;
      calendarApp = createCalendar({
        calendars: calendarsVariants,
        selectedDate: Temporal.now,
        timezone: document.querySelector('body').dataset.userTimezone || 'UTC',
        weekOptions: {
          timeAxisFormatOptions: {
            hour: '2-digit',
            hour12: false,
            hourCycle: 'h24'
          }
        },
        firstDayOfWeek: 7, // Sunday
        views: [
          createViewDay(),
          createViewWeek(),
          createViewMonthGrid(),
        ],
        defaultView: createViewMonthGrid().name,
        callbacks: {
          onRangeUpdate(range) {
            component.startDate = range.start.toPlainDateTime()['o'];
            component.endDate = range.end.toPlainDateTime()['o'];
            component.fetchEvents();
          },
          beforeRender($app) {
            const range = $app.calendarState.range.value
            component.startDate = range.start.toPlainDateTime()['o'];
            component.endDate = range.end.toPlainDateTime()['o'];
            component.fetchEvents();
          },
        }
      }, [eventsServicePlugin]);
    },
    components: {
      ScheduleXCalendar
    },
    watch: {
      repositoryId() {
        this.fetchEvents();
      },
      filters: {
        handler() {
          this.fetchEvents();
        },
        deep: true
      }
    },
    methods: {
      fetchEvents() {
        const params = {
          repository_id: this.repositoryId,
          filters: this.filters,
          start_date: this.startDate,
          end_date: this.endDate,
          event_type: 'equipment_booking'
        };
        axios.get(this.eventsUrl, { params })
          .then(response => {
            let events = response.data.data.map((event) => {
              let start, end;

              if (event.attributes.full_day) {
                start = Temporal.PlainDate.from(event.attributes.start_at.split('T')[0]);
                end = Temporal.PlainDate.from(event.attributes.end_at.split('T')[0]);
              } else {
                start = Temporal.Instant.from(event.attributes.start_at).toZonedDateTimeISO('UTC');
                end = Temporal.Instant.from(event.attributes.end_at).toZonedDateTimeISO('UTC');
              }

              return {
                id: event.id,
                title: event.attributes.name,
                start: start,
                end: end,
                calendarId: event.attributes.event_sub_type || 'no_type',
              };
            });
            eventsServicePlugin.set(events);
          })
          .catch(error => {
            console.error('Error fetching events:', error);
          });
      }
    }
  };
</script>
