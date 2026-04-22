<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label">
            {{ i18n.t('equipment_bookings.index.manage_modal.create_title') }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="flex flex-col gap-4">
            <div>
              <span class="sci-label">
                {{ i18n.t('equipment_bookings.index.manage_modal.event_name') }}
              </span>
              <div class="sci-input-container-v2">
                <input type="text" v-model="event.event_name" />
              </div>
            </div>
            <div>
              <span class="sci-label">
                {{ i18n.t('equipment_bookings.index.manage_modal.item') }}
              </span>
              <SelectDropdown
                :optionsUrl="repositoryRowsUrl"
                ajaxMethod="post"
                :placeholder="i18n.t('equipment_bookings.index.manage_modal.select_item')"
                :searchable="true"
                :value="event.repository_row_id"
                @change="event.repository_row_id = $event"
              ></SelectDropdown>
            </div>
            <div>
              <span class="sci-label">
                {{ i18n.t('equipment_bookings.index.manage_modal.event_type') }}
              </span>
              <SelectDropdown
                :options="eventTypes"
                :searchable="false"
                :value="event.event_sub_type"
                @change="event.event_sub_type = $event"
              ></SelectDropdown>
            </div>
            <div class="flex gap-2">
              <div>
                <span class="sci-label">
                  {{ i18n.t('equipment_bookings.index.manage_modal.start_date') }}
                </span>
                <DateTimePicker
                  :key="event.full_day"
                  @change="event.start_at = $event"
                  :defaultValue="event.start_at"
                  :mode="event.full_day ? 'date' : 'datetime'"
                  size="mb"
                  :clearable="false"
                />
              </div>
              <div class="flex items-center h-10 mt-5">
                {{ i18n.t('equipment_bookings.index.manage_modal.until') }}
              </div>
              <div>
                <span class="sci-label">
                  {{ i18n.t('equipment_bookings.index.manage_modal.end_date') }}
                </span>
                <DateTimePicker
                  :key="event.full_day"
                  @change="event.end_at = $event"
                  :defaultValue="event.end_at"
                  :mode="event.full_day ? 'date' : 'datetime'"
                  size="mb"
                  :clearable="false"
                />
              </div>
            </div>
            <div class="flex items-center gap-2">
              <span class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox" v-model="event.full_day" />
                <span class="sci-checkbox-label"></span>
              </span>
              <span class="sci-label">{{ i18n.t('equipment_bookings.index.manage_modal.full_day_event') }}</span>
            </div>
            <div>
              <span class="sci-label">{{ i18n.t('equipment_bookings.index.manage_modal.frequency') }}</span>
              <SelectDropdown
                :options="frequencies"
                :searchable="false"
                :value="event.frequency"
                @change="event.frequency = $event"
              ></SelectDropdown>
            </div>
            <div v-if="event.frequency === 'custom'" class="rounded p-4 bg-sn-super-light-grey">
              <div class="flex items-center">
                <span class="mr-4">{{ i18n.t('equipment_bookings.index.manage_modal.repeat_every') }}</span>
                <div class="sci-input-container-v2 w-24 mr-1">
                  <input type="number" class="!bg-white" min="1" v-model.number="event.custom_frequency.every" />
                </div>
                <div class="w-32">
                  <SelectDropdown
                    class="bg-white"
                    :options="customFrequencyUnits"
                    :searchable="false"
                    :value="event.custom_frequency.units"
                    @change="event.custom_frequency.units = $event"
                  ></SelectDropdown>
                </div>
              </div>
              <div class="sci-label my-4 !text-sn-grey-700">
                {{ i18n.t('equipment_bookings.index.manage_modal.ends') }}
              </div>
              <div class="flex items-start gap-1 flex-col">
                <div class="flex items-center gap-2 h-11">
                  <span class="sci-radio-container">
                    <input type="radio" class="sci-radio" v-model="event.custom_frequency.mode" value="infinite" />
                    <span class="sci-radio-label"></span>
                  </span>
                  <span class="sci-label">{{ i18n.t('equipment_bookings.index.manage_modal.never') }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="sci-radio-container">
                    <input type="radio" class="sci-radio" v-model="event.custom_frequency.mode" value="occurrences" />
                    <span class="sci-radio-label"></span>
                  </span>
                  <div class="sci-label w-12">{{ i18n.t('equipment_bookings.index.manage_modal.after') }}</div>
                  <div class="sci-input-container-v2 w-24 ml-10">
                    <input type="number" class="!bg-white" min="1" v-model.number="event.custom_frequency.occurrences" />
                  </div>
                  <span class="sci-label">{{ i18n.t('equipment_bookings.index.manage_modal.occassions') }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="sci-radio-container">
                    <input type="radio" class="sci-radio" v-model="event.custom_frequency.mode" value="end_date" />
                    <span class="sci-radio-label"></span>
                  </span>
                  <div class="sci-label w-12">{{ i18n.t('equipment_bookings.index.manage_modal.on_date') }}</div>
                  <DateTimePicker
                    class="ml-10"
                    @change="event.custom_frequency.end_date = $event"
                    :defaultValue="event.custom_frequency.end_date"
                    mode="date"
                    size="mb"
                    :clearable="false"
                  />
                </div>
              </div>
            </div>
            <div>
              <span class="sci-label">
                {{ i18n.t('equipment_bookings.index.manage_modal.people') }}
              </span>
              <SelectDropdown
              :optionsUrl="usersUrl"
              :multiple="true"
              :withCheckboxes="true"
              :searchable="true"
              :value="event.users"
              @change="event.users = $event"
              :option-renderer="usersRenderer"
              :label-renderer="usersRenderer"
              ></SelectDropdown>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
          <button type="button" class="btn btn-primary" :disabled="disabled" @click="createEvent">
            {{ i18n.t('equipment_bookings.index.manage_modal.create_event') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import modalMixin from '../shared/modal_mixin';
import SelectDropdown from '../shared/select_dropdown.vue';
import usersRenderer from '../shared/select_dropdown_renderers/user.vue';
import DateTimePicker from '../shared/date_time_picker.vue';
import axios from '../../packs/custom_axios.js';
import {
  rows_list_team_repositories_path,
  users_filter_projects_path,
  calendar_events_path
} from '../../routes.js';

export default {
  name: 'EventManageModal',
  props: {
    repositoryId: {
      type: Number,
      required: true
    }
  },
  data() {
    return {
      creating: false,
      teamId: null,
      eventTypes: [
        ['calibration', this.i18n.t('equipment_bookings.index.sidebar.event_types.calibration')],
        ['maintenance', this.i18n.t('equipment_bookings.index.sidebar.event_types.maintenance')],
        ['usage', this.i18n.t('equipment_bookings.index.sidebar.event_types.usage')],
        ['no_type', this.i18n.t('equipment_bookings.index.sidebar.event_types.other')]
      ],
      event: {
        event_name: '',
        repository_row_id: null,
        event_type: 'equipment_booking',
        event_sub_type: 'calibration',
        start_at: null,
        end_at: null,
        full_day: false,
        frequency: 'once',
        custom_frequency: {
          every: 1,
          units: 'week',
          mode: 'infinite',
          end_date: null,
          occurrences: 1,
        },
        users: []
      },
      frequencies: [
        ['once', this.i18n.t('equipment_bookings.index.manage_modal.frequency_options.once')],
        ['daily', this.i18n.t('equipment_bookings.index.manage_modal.frequency_options.daily')],
        ['weekly', this.i18n.t('equipment_bookings.index.manage_modal.frequency_options.weekly')],
        ['monthly', this.i18n.t('equipment_bookings.index.manage_modal.frequency_options.monthly')],
        ['custom', this.i18n.t('equipment_bookings.index.manage_modal.frequency_options.custom')]
      ],
      customFrequencyUnits: [
        ['day', this.i18n.t('equipment_bookings.index.manage_modal.custom_frequency_units.day')],
        ['week', this.i18n.t('equipment_bookings.index.manage_modal.custom_frequency_units.week')],
        ['month', this.i18n.t('equipment_bookings.index.manage_modal.custom_frequency_units.month')],
        ['year', this.i18n.t('equipment_bookings.index.manage_modal.custom_frequency_units.year')]
      ]
    };
  },
  created() {
    this.teamId = document.body.dataset.currentTeamId;

    const now = new Date();
    const later = new Date(now.getTime() + 60 * 60 * 1000);
    const tillDate = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const formatDateTime = (date) => {
      const pad = (n) => n.toString().padStart(2, '0');
      return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
    };

    this.event.start_at = formatDateTime(now);
    this.event.end_at = formatDateTime(later);
    this.event.custom_frequency.end_date = formatDateTime(tillDate);
  },
  computed: {
    disabled() {
      return this.event.event_name.length === 0 || !this.event.repository_row_id || this.creating;
    },
    repositoryRowsUrl() {
      return rows_list_team_repositories_path(this.teamId, { active: true, repository_id: this.repositoryId });
    },
    usersUrl() {
      return users_filter_projects_path();
    },
    calendarEventsUrl() {
      return calendar_events_path();
    },
    usersRenderer() {
      return usersRenderer;
    }
  },
  components: {
    SelectDropdown,
    DateTimePicker
  },
  mixins: [modalMixin],
  methods: {
    createEvent() {
      if (this.creating) return;

      this.creating = true;

      const payload = {
        name: this.event.event_name,
        repository_row_id: this.event.repository_row_id,
        event_type: this.event.event_type,
        event_sub_type: this.event.event_sub_type,
        start_at: this.event.start_at,
        end_at: this.event.end_at,
        full_day: this.event.full_day,
        calendar_event_participants_attributes: this.event.users.map(user_id => ({ user_id })),
      };

      axios.post(this.calendarEventsUrl, payload)
        .then(() => {
          this.$emit('event:created');
        })
        .finally(() => {
          this.creating = false;
        });
    }
  }
};
</script>
