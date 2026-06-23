<template>
  <div class="w-[300px] flex-shrink-0 p-2 pr-4 flex flex-col gap-6 border-transparent !border-r-sn-light-grey border-solid  h-full">
    <div>
      <button
        class="btn btn-primary w-full"
        @click="createEvent = true"
        :disabled="!permissions.create_equipment_bookings"
        data-e2e="e2e-BT-equipmentBooking-newEvent">
        <i class="sn-icon sn-icon-new-task"></i>
        {{ i18n.t('equipment_bookings.index.sidebar.new_event') }}
      </button>
    </div>
    <div class="flex flex-col gap-3">
      <div class="mb-3">
        <label>{{ i18n.t('equipment_bookings.index.show_calendar') }}</label>
        <SelectDropdown
          :options="repositories"
          :searchable="true"
          :value="repositoryId"
          :optionRenderer="repositoryRenderer"
          :labelRenderer="repositoryRenderer"
          @change="$emit('update:repository', $event)"
        ></SelectDropdown>
      </div>
      <div
        v-for="eventType in eventTypes"
        :key="eventType.value"
        class="flex items-center gap-2 cursor-pointer"
        @click="$emit('update:filters', { ...filters, sub_types: { ...filters['sub_types'], [eventType.value]: !filters['sub_types'][eventType.value] } })"
      >
        <div class="w-7 h-7 p-1 relative">
          <div
            :style="{
              backgroundColor: filters['sub_types'][eventType.value] ? eventType.color : '#FFF',
              border: `1px solid ${eventType.color}`
            }"
            class="w-full h-full">
          </div>
          <i class="sn-icon sn-icon-check absolute top-0.5 left-0.5 text-white" style="font-size: 16px"></i>
        </div>
        <div>{{ eventType.label }}</div>
      </div>
    </div>
    <div>
      <div class="flex items-center">
        <label>
          {{ i18n.t('equipment_bookings.index.sidebar.filter_items') }}
        </label>
        <span
          v-if="filters.subject_ids.length > 0"
          class="cursor-pointer ml-auto text-sn-blue text-xs"
          @click="$emit('update:filters', { ...filters, subject_ids: [] })">
          {{ i18n.t('general.clear') }}
        </span>
      </div>
      <SelectDropdown
        :optionsUrl="assignedRepositoryRowsUrl"
        :placeholder="i18n.t('equipment_bookings.index.sidebar.all_items_selected')"
        :multiple="true"
        :withCheckboxes="true"
        :searchable="true"
        :hideSelectAll="true"
        :value="filters.subject_ids"
        @change="$emit('update:filters', { ...filters, subject_ids: $event })"
      ></SelectDropdown>
    </div>
    <div>
      <div class="flex items-center">
        <label>
          {{ i18n.t('equipment_bookings.index.sidebar.filter_people') }}
        </label>
        <span
          v-if="filters.assigned_user_ids.length > 0"
          class="cursor-pointer ml-auto text-sn-blue text-xs"
          @click="$emit('update:filters', { ...filters, assigned_user_ids: [] })">
          {{ i18n.t('general.clear') }}
        </span>
      </div>
      <SelectDropdown
        :optionsUrl="assignedUsersUrl"
        :placeholder="i18n.t('equipment_bookings.index.sidebar.all_users_selected')"
        :multiple="true"
        :withCheckboxes="true"
        :searchable="true"
        :hideSelectAll="true"
        :value="filters.assigned_user_ids"
        :option-renderer="usersRenderer"
        :label-renderer="usersRenderer"
        @change="$emit('update:filters', { ...filters, assigned_user_ids: $event })"
      ></SelectDropdown>
    </div>
    <manageEventModal
      v-if="createEvent"
      :repositoryId="repositoryId"
      @close="createEvent = false"
      @event:created="createEvent = false; $emit('event:created')"
    ></manageEventModal>
  </div>
</template>

<script>
import SelectDropdown from '../shared/select_dropdown.vue';
import usersRenderer from '../shared/select_dropdown_renderers/user.vue';
import repositoryRenderer from './renderers/repository.vue';
import manageEventModal from './manage_modal.vue';
import {
  assigned_repository_rows_equipment_bookings_path,
  assigned_users_equipment_bookings_path
} from '../../routes.js';

export default {
  name: 'EquipmentBookingsFilters',
  props: {
    filters: {
      type: Object,
      required: true
    },
    repositoryId: {
      type: Number,
      required: true
    },
    permissions: {
      type: Object,
      required: true
    },
    repositories: {
      type: Array,
      required: true
    }
  },
  components: {
    SelectDropdown,
    usersRenderer,
    manageEventModal,
    repositoryRenderer
  },
  computed: {
    assignedRepositoryRowsUrl() {
      return assigned_repository_rows_equipment_bookings_path({ repository_id: this.repositoryId });
    },
    assignedUsersUrl() {
      return assigned_users_equipment_bookings_path({ repository_id: this.repositoryId, mode: 'assigned_only'});
    },
    usersRenderer() {
      return usersRenderer;
    },
    repositoryRenderer() {
      return repositoryRenderer;
    }
  },
  data() {
    return {
      createEvent: false,
      eventTypes: [
        { value: 'calibration', label: this.i18n.t('equipment_bookings.index.sidebar.event_types.calibration'), color: '#E9A845' },
        { value: 'maintenance', label: this.i18n.t('equipment_bookings.index.sidebar.event_types.maintenance'), color: '#DF3562' },
        { value: 'usage', label: this.i18n.t('equipment_bookings.index.sidebar.event_types.usage'), color: '#3B99FD' },
        { value: 'no_type', label: this.i18n.t('equipment_bookings.index.sidebar.event_types.other'), color: '#6F2DC1' }
      ],
    };
  },
};
</script>
