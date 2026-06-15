<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 v-if="event.id" class="modal-title truncate !block" id="edit-project-modal-label">
            {{ i18n.t('equipment_bookings.index.manage_modal.update_title') }}
          </h4>
          <h4 v-else class="modal-title truncate !block" id="edit-project-modal-label">
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
                <input type="text" ref="eventNameInput" v-model="event.event_name" />
              </div>
            </div>
            <div>
              <RepositoryRowSelector
                :preSelectedRepository="repositoryId"
                :hideRepositorySelector="true"
                :preSelectedRows="event.repository_row_id"
                :disableRowSelection="!!repositoryRowId"
                @change="event.repository_row_id = $event"
              />
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
              <div class="grow">
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
              <div class="flex items-center h-10 mt-5 shrink-0">
                {{ i18n.t('equipment_bookings.index.manage_modal.until') }}
              </div>
              <div class="grow">
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
            <div v-if="event.frequency === 'CUSTOM'" class="rounded p-4 bg-sn-super-light-grey">
              <div class="flex items-center">
                <span class="mr-4">{{ i18n.t('equipment_bookings.index.manage_modal.repeat_every') }}</span>
                <div class="sci-input-container-v2 w-24 mr-1">
                  <input type="number" class="!bg-white" min="1" v-model.number="event.interval" />
                </div>
                <div class="w-32">
                  <SelectDropdown
                    class="bg-white"
                    :options="customFrequencyUnits"
                    :searchable="false"
                    :value="event.interval_unit"
                    @change="event.interval_unit = $event"
                  ></SelectDropdown>
                </div>
              </div>
              <div class="sci-label my-4 !text-sn-grey-700">
                {{ i18n.t('equipment_bookings.index.manage_modal.ends') }}
              </div>
              <div class="flex items-start gap-1 flex-col">
                <div class="flex items-center gap-2 h-11">
                  <span class="sci-radio-container">
                    <input type="radio" class="sci-radio" v-model="event.repeat_mode" value="infinite" />
                    <span class="sci-radio-label"></span>
                  </span>
                  <span class="sci-label">{{ i18n.t('equipment_bookings.index.manage_modal.never') }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="sci-radio-container">
                    <input type="radio" class="sci-radio" v-model="event.repeat_mode" value="occurrences" />
                    <span class="sci-radio-label"></span>
                  </span>
                  <div class="sci-label w-12">{{ i18n.t('equipment_bookings.index.manage_modal.after') }}</div>
                  <div class="sci-input-container-v2 w-24 ml-10">
                    <input type="number" class="!bg-white" min="1" v-model.number="event.repeat_count" />
                  </div>
                  <span class="sci-label">{{ i18n.t('equipment_bookings.index.manage_modal.occassions') }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="sci-radio-container">
                    <input type="radio" class="sci-radio" v-model="event.repeat_mode" value="end_date" />
                    <span class="sci-radio-label"></span>
                  </span>
                  <div class="sci-label w-12">{{ i18n.t('equipment_bookings.index.manage_modal.on_date') }}</div>
                  <DateTimePicker
                    class="ml-10"
                    @change="event.repeat_until = $event"
                    :defaultValue="event.repeat_until"
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
          <button v-if="event.id" type="button" class="btn btn-primary" :disabled="disabled" @click="updateEvent">
            {{ i18n.t('equipment_bookings.index.manage_modal.update_event') }}
          </button>
          <button v-else type="button" class="btn btn-primary" :disabled="disabled" @click="createEvent">
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
import RepositoryRowSelector from '../shared/repository_row_selector.vue';
import usersRenderer from '../shared/select_dropdown_renderers/user.vue';
import DateTimePicker from '../shared/date_time_picker.vue';
import axios from '../../packs/custom_axios.js';
import {
  rows_list_team_repositories_path,
  users_filter_projects_path,
  calendar_events_path,
  calendar_event_path
} from '../../routes.js';

export default {
  name: 'EventManageModal',
  props: {
    repositoryId: {
      type: Number,
      required: true
    },
    existedEvent: {
      type: Object,
      required: false
    },
    repositoryRowId: {
      type: Number,
      required: false
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
        repository_row_id: this.repositoryRowId,
        event_type: 'equipment_booking',
        event_sub_type: 'calibration',
        start_at: null,
        end_at: null,
        full_day: false,
        frequency: 'ONCE',
        interval: 1,
        interval_unit: 'WEEKLY',
        repeat_mode: 'infinite',
        repeat_count: 1,
        repeat_until: null,
        users: []
      },
      frequencies: [
        ['ONCE', this.i18n.t('equipment_bookings.index.manage_modal.frequency_options.once')],
        ['DAILY', this.i18n.t('equipment_bookings.index.manage_modal.frequency_options.daily')],
        ['WEEKLY', this.i18n.t('equipment_bookings.index.manage_modal.frequency_options.weekly')],
        ['MONTHLY', this.i18n.t('equipment_bookings.index.manage_modal.frequency_options.monthly')],
        ['CUSTOM', this.i18n.t('equipment_bookings.index.manage_modal.frequency_options.custom')]
      ],
      customFrequencyUnits: [
        ['DAILY', this.i18n.t('equipment_bookings.index.manage_modal.custom_frequency_units.days')],
        ['WEEKLY', this.i18n.t('equipment_bookings.index.manage_modal.custom_frequency_units.weeks')],
        ['MONTHLY', this.i18n.t('equipment_bookings.index.manage_modal.custom_frequency_units.months')],
        ['YEARLY', this.i18n.t('equipment_bookings.index.manage_modal.custom_frequency_units.years')]
      ]
    };
  },
  created() {
    this.teamId = document.body.dataset.currentTeamId;

    if (this.existedEvent) {
      this.event = { ...this.existedEvent };
      if (this.event.frequency === 'CUSTOM') {
        if (this.event.repeat_count) this.event.repeat_mode = 'occurrences';
        else if (this.event.repeat_until) this.event.repeat_mode = 'end_date';
        else this.event.repeat_mode = 'infinite';
      }
    }

    if (!this.event.start_at && !this.event.end_at) {
      this.setDefaultDates();
    }
  },
  mounted() {
    this.$nextTick(() => {
      this.$refs.eventNameInput.focus();
    });
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
    calendarEventUrl() {
      if (!this.event.id) return null;

      return calendar_event_path(this.event.id);
    },
    usersRenderer() {
      return usersRenderer;
    }
  },
  components: {
    SelectDropdown,
    DateTimePicker,
    RepositoryRowSelector
  },
  mixins: [modalMixin],
  methods: {
    setDefaultDates() {
      // i need for now set next avaialble hour and 0 minutes and seconds

      const now = new Date();
      now.setMinutes(0);
      now.setSeconds(0);
      const from = new Date(now.getTime() + 60 * 60 * 1000);
      const to = new Date(from.getTime() + 60 * 60 * 1000);

      const formatDateTime = (date) => {
        const pad = (n) => n.toString().padStart(2, '0');
        return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
      };

      this.event.start_at = formatDateTime(from);
      this.event.end_at = formatDateTime(to);
    },
    preparePayload() {
      return {
        name: this.event.event_name,
        subject_id: this.event.repository_row_id,
        subject_type: 'RepositoryRow',
        event_type: this.event.event_type,
        event_sub_type: this.event.event_sub_type,
        start_at: this.event.start_at,
        end_at: this.event.end_at,
        full_day: this.event.full_day,
        user_ids: this.event.users,
        frequency: this.event.frequency,
        interval: this.event.frequency === 'CUSTOM' ? this.event.interval : null,
        interval_unit: this.event.frequency === 'CUSTOM' ? this.event.interval_unit : null,
        repeat_count: this.event.frequency === 'CUSTOM' && this.event.repeat_mode === 'occurrences' ? this.event.repeat_count : null,
        repeat_until: this.event.frequency === 'CUSTOM' && this.event.repeat_mode === 'end_date' ? this.event.repeat_until : null
      };
    },
    updateEvent() {
      if (this.creating) return;

      this.creating = true;

      const payload = this.preparePayload();

      axios.patch(this.calendarEventUrl, payload)
        .then(() => {
          this.$emit('event:updated');
        })
        .finally(() => {
          this.creating = false;
        });
    },
    createEvent() {
      if (this.creating) return;

      this.creating = true;

      const payload = this.preparePayload();

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
