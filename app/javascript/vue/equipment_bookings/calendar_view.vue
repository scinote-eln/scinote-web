<template>
  <div class="calendar-view w-full">
    <ScheduleXCalendar
      v-if="calendarApp"
      :custom-components="customComponents"
      :calendar-app="calendarApp"
      class="w-full h-full"
    />
    <ManageModal
      v-if="selectedEvent"
      :existed-event="selectedEvent"
      :repositoryId="repositoryId"
      @event:updated="fetchEvents(); selectedEvent = null"
      @event:created="fetchEvents(); selectedEvent = null"
      @close="selectedEvent = null"
    />
    <ConfirmationModal
    :title="i18n.t('equipment_bookings.index.delete_modal.title')"
    :description="i18n.t('equipment_bookings.index.delete_modal.description_html')"
    confirmClass="btn btn-danger"
    :confirmText="i18n.t('equipment_bookings.index.delete_modal.delete')"
    ref="deleteEventModal"
  ></ConfirmationModal>
  </div>
</template>

<script>
  import axios from '../../packs/custom_axios.js';
  import { ScheduleXCalendar } from '@schedule-x/vue'
  import { h } from 'vue'
  import { createEventModalPlugin } from '@schedule-x/event-modal'
  import ManageModal from './manage_modal.vue';
  import ConfirmationModal from '../shared/confirmation_modal.vue';
  import {
    createCalendar,
    createViewDay,
    createViewMonthGrid,
    createViewWeek,
  } from '@schedule-x/calendar'
  import { createEventRecurrencePlugin, createEventsServicePlugin } from "@schedule-x/event-recurrence";

  import 'temporal-polyfill/global'
  import {
    calendar_events_path
  } from '../../routes.js';
import { loadScript } from 'pdfjs-dist';

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
      },
      loadEvents: {
        type: Number,
        required: true
      }
    },
    data() {
      return {
        selectedEvent: null,
        eventsServicePlugin: null,
        eventModalPlugin: null,
        eventRecurrencePlugin: null
      };
    },
    computed: {
      calendarApp() {
        return calendarApp;
      },
      customComponents() {
        return {
          eventModal: ({ calendarEvent }) => {
            return h('div', {
              class: 'p-6 shadow rounded-lg border border-solid !border-sn-super-light-grey',
            },
            [
              h('div', { class: 'flex items-center gap-2 mb-2'},
                [
                  h('div', { class: `h-6 w-6 rounded`, style: { backgroundColor: calendarEvent.color } }),
                  h('h3', { class: 'font-semibold my-0 grow' }, calendarEvent.title),
                  h('button', {
                    class: 'btn btn-light icon-btn btn-black',
                    onClick: () => this.duplicateEvent(calendarEvent)
                  }, h('i', { class: 'sn-icon sn-icon-duplicate' })),
                  h('button', {
                    class: 'btn btn-light icon-btn btn-black',
                    onClick: () => this.editEvent(calendarEvent)
                  }, h('i', { class: 'sn-icon sn-icon-edit' })),
                  h('button', {
                    class: 'btn btn-light icon-btn btn-black',
                    onClick: () => this.removeEvent(calendarEvent)
                  }, h('i', { class: 'sn-icon sn-icon-delete' }))
                ]
              ),
              h('div', { class: 'flex items-center gap-2 mb-2' }, [
                h('i', { class: 'sn-icon sn-icon-created' }),
                h('span', {}, `${calendarEvent.attributes.start_at_formatted} - ${calendarEvent.attributes.end_at_formatted}`)
              ]),
              calendarEvent.attributes.users && calendarEvent.attributes.users.length > 0 && h('div', { class: 'flex items-center gap-2 mb-2' }, [
                h('i', { class: 'sn-icon sn-icon-user' }),
                h('span', {}, calendarEvent.attributes.users.map(user => user.name).join(', '))
              ]),
              calendarEvent.attributes.subject && h('div', { class: 'flex items-center gap-2' }, [
                h('i', { class: 'sn-icon sn-icon-inventory' }),
                h('a', {
                  class: 'hover:no-underline record-info-link truncate block cursor-pointer',
                  href: calendarEvent.attributes.subject.url},
                `${calendarEvent.attributes.subject.name} (${calendarEvent.attributes.subject.code})`)
              ])
            ]);
          },
        };
      },
      eventsUrl() {
        return calendar_events_path();
      }
    },
    created() {
      const component = this;

      this.eventsServicePlugin = createEventsServicePlugin();
      this.eventModalPlugin = createEventModalPlugin();
      this.eventRecurrencePlugin = createEventRecurrencePlugin();

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
      }, [this.eventRecurrencePlugin, this.eventsServicePlugin, this.eventModalPlugin]);
    },
    components: {
      ScheduleXCalendar,
      ManageModal,
      ConfirmationModal
    },
    watch: {
      loadEvents() {
        this.fetchEvents();
      },
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
      convertRawDateStringToString(date) {
        return date.toString().replace('T', ' ').substring(0, 16);
      },
      buildRRule(attrs) {
        const { frequency, interval, interval_unit, repeat_count, repeat_until } = attrs;
        if (!frequency || frequency === 'ONCE') return null;
        if (frequency !== 'CUSTOM') return `FREQ=${frequency}`;
        let rule = `FREQ=${interval_unit}`;
        if (interval > 1) rule += `;INTERVAL=${interval}`;
        if (repeat_count) rule += `;COUNT=${repeat_count}`;
        else if (repeat_until) rule += `;UNTIL=${new Date(repeat_until).toISOString().replace(/[-:]/g, '').split('.')[0]}Z`;
        return rule;
      },
      duplicateEvent(event) {
        this.selectedEvent = {
          id: null,
          event_name: event.title,
          start_at: null,
          end_at: null,
          event_type: event.attributes.event_type,
          full_day: event.attributes.full_day,
          users: event.attributes.users.map(user => user.id),
          repository_row_id: event.attributes.subject.id,
          event_sub_type: event.attributes.event_sub_type,
        }
      },
      editEvent(event) {
        this.selectedEvent = {
          id: event.id,
          event_name: event.title,
          start_at: this.convertRawDateStringToString(event.attributes.start_at_string),
          end_at: this.convertRawDateStringToString(event.attributes.end_at_string),
          event_type: event.attributes.event_type,
          full_day: event.attributes.full_day,
          users: event.attributes.users.map(user => user.id),
          repository_row_id: event.attributes.subject.id,
          event_sub_type: event.attributes.event_sub_type,
        }
      },
      async removeEvent(event) {
        const ok = await this.$refs.deleteEventModal.show();
        if (ok) {
          axios.delete(event.attributes.urls.delete_url).then(() => {
            this.fetchEvents();
          })
        }
      },
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
                start = Temporal.PlainDate.from(event.attributes.start_at_string);
                end = Temporal.PlainDate.from(event.attributes.end_at_string);
              } else {
                start = Temporal.Instant.from(event.attributes.start_at_string).toZonedDateTimeISO('UTC');
                end = Temporal.Instant.from(event.attributes.end_at_string).toZonedDateTimeISO('UTC');
              }

              return {
                id: event.id,
                title: event.attributes.name,
                start: start,
                end: end,
                color: calendarsVariants[event.attributes.event_sub_type || 'no_type'].lightColors.main,
                attributes: event.attributes,
                calendarId: event.attributes.event_sub_type || 'no_type',
                rrule: this.buildRRule(event.attributes)
              };
            });
            this.eventsServicePlugin.set(events);
          })
          .catch(error => {
            console.error('Error fetching events:', error);
          });
      }
    }
  };
</script>
