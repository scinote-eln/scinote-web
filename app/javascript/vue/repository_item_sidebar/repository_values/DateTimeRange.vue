<template>
  <div>
    <div
      @click="enableEdit"
      v-click-outside="validateAndSave"
      class="text-sn-dark-grey font-inter text-sm font-normal leading-5 w-full rounded relative"
      :class="editableClassName"
    >
      <div v-if="dateType === 'date'">
        <div v-if="isEditing || values?.datetime" ref="edit">
          <DateTimePicker
            :disabled="!canEdit"
            @change="formatDateTime($event)"
            :selectorId="`DatePicker${colId}`"
            :dateOnly="true"
            :defaultValue="dateValue(values?.datetime)"
            :standAlone="true"
          />
        </div>
        <div v-else ref="view" :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }" >
          {{ i18n.t(`repositories.item_card.repository_date_value.${canEdit ? 'placeholder' : 'no_date'}`) }}
        </div>
      </div>
      <div v-else-if="dateType === 'dateRange'">
        <div v-if="isEditing || (timeFrom?.datetime && timeTo?.datetime)" ref="edit" class="w-full flex align-center">
          <div>
            <DateTimePicker
              :disabled="!canEdit"
              @change="formatDateTime($event, 'start_time')"
              :selectorId="`DatePickerStart${colId}`"
              :dateOnly="true"
              :defaultValue="dateValue(timeFrom?.datetime)"
              :standAlone="true"
              :dateClassName="hasMonthText() ? 'w-[135px]' : 'w-[90px]'"
            />
          </div>
          <span class="mr-3">-</span>
          <div>
            <DateTimePicker
              :disabled="!canEdit"
            @change="formatDateTime($event, 'end_time')"
            :selectorId="`DatePickerEnd${colId}`"
            :dateOnly="true"
            :defaultValue="dateValue(timeTo?.datetime)"
            :standAlone="true"
            :dateClassName="hasMonthText() ? 'w-[135px]' : 'ml-2 w-[90px]'"
            />
          </div>
        </div>
        <div v-else ref="view" :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }" >
          {{ i18n.t(`repositories.item_card.repository_date_range_value.${canEdit ? 'placeholder' : 'no_date_range'}`) }}
        </div>
      </div>
      <div v-if="dateType === 'dateTime'">
        <div v-if="isEditing || values?.datetime" ref="edit" class="w-full">
          <DateTimePicker
            :disabled="!canEdit"
            @change="formatDateTime"
            :selectorId="`DatePicker${colId}`"
            :defaultValue="dateValue(values?.datetime)"
            :standAlone="true"
            :dateClassName="hasMonthText() ? 'w-[135px]' : 'w-[90px]'"
            timeClassName="w-11"
          />
        </div>
        <div v-else ref="view" :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }" >
          {{ i18n.t(`repositories.item_card.repository_date_time_value.${canEdit ? 'placeholder' : 'no_date_time'}`) }}
        </div>
      </div>
      <div v-else-if="dateType === 'dateTimeRange'">
        <div v-if="isEditing || (timeFrom?.datetime && timeTo?.datetime)" ref="edit" class="w-full flex">
          <div>
            <DateTimePicker
              :disabled="!canEdit"
              @change="formatDateTime($event, 'start_time')"
              :selectorId="`DatePickerStart${colId}`"
              :defaultValue="dateValue(timeFrom?.datetime)"
              :timeOnly="false"
              :dateOnly="false"
              :standAlone="true"
              :dateClassName="hasMonthText() ? 'w-[135px]' : 'w-[90px]'"
              timeClassName="w-11"
            />
          </div>
          <span class="mx-1">-</span>
          <div>
            <DateTimePicker
              :disabled="!canEdit"
              @change="formatDateTime($event, 'end_time')"
              :selectorId="`DatePickerEnd${colId}`"
              :defaultValue="dateValue(timeTo?.datetime)"
              :timeOnly="false"
              :dateOnly="false"
              :standAlone="true"
              :dateClassName="hasMonthText() ? 'w-[135px]' : 'ml-2 w-[90px]'"
              timeClassName="w-11"
            />
          </div>
        </div>
        <div v-else ref="view" :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }" >
          {{ i18n.t(`repositories.item_card.repository_date_time_range_value.${canEdit ? 'placeholder' : 'no_date_time_range'}`) }}
        </div>
      </div>
      <div v-else-if="dateType === 'time'">
        <div v-if="isEditing || values?.datetime" ref="edit">
          <DateTimePicker
            :disabled="!canEdit"
            @change="formatDateTime"
            :selectorId="`DatePicker${colId}`"
            :timeOnly="true"
            :defaultValue="dateValue(values?.datetime)"
            :standAlone="true"
            timeClassName="w-11"
          />
        </div>
        <div v-else ref="view" :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }">
          {{ i18n.t(`repositories.item_card.repository_time_value.${ canEdit ? 'placeholder' : 'no_time'}`) }}
        </div>
      </div>
      <div v-else-if="dateType === 'timeRange'">
        <div v-if="isEditing || (timeFrom?.datetime && timeTo?.datetime)" ref="edit" class="w-full flex">
          <div>
            <DateTimePicker
              :disabled="!canEdit"
              @change="formatDateTime($event, 'start_time')"
              :selectorId="`DatePickerStart${colId}`"
              :timeOnly="true"
              :defaultValue="dateValue(timeFrom?.datetime)"
              :standAlone="true"
              timeClassName="w-11"
            />
          </div>
          <span class="mx-1">-</span>
          <div>
            <DateTimePicker
              :disabled="!canEdit"
              @change="formatDateTime($event, 'end_time')"
              :selectorId="`DatePickerEnd${colId}`"
              :timeOnly="true"
              :defaultValue="dateValue(timeTo?.datetime)"
              :standAlone="true"
              timeClassName="ml-2 w-11"
            />
          </div>
        </div>
        <div v-else ref="view" :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }">
          {{ i18n.t(`repositories.item_card.repository_time_range_value.${canEdit ? 'placeholder' : 'no_time_range'}`) }}
        </div>
      </div>
      <span class="absolute right-2 top-1.5" v-if="values?.reminder">
        <Reminder :value="values" />
      </span>
    </div>
    <div class="text-sn-delete-red text-xs w-full " :class="{ visible: errorMessage, invisible: !errorMessage }">
      {{ errorMessage }}
    </div>
  </div>
</template>

<script>
  import { vOnClickOutside } from '@vueuse/components'
  import date_time_range from './../mixins/date_time_range';
  import DateTimePicker from '../../shared/date_time_picker.vue';
  import Reminder from './../reminder.vue';

  export default {
    name: 'DateTimeRange',
    mixins: [date_time_range],
    components: {
      DateTimePicker,
      Reminder
    },
    directives: {
      'click-outside': vOnClickOutside
    },
    data() {
      return {
        values: {},
        errorMessage: null,
        params: null,
        cellUpdatePath: null,
        timeFrom: null,
        timeTo: null,
        isEditing: false,
        initValue: null,
        initStartDate: null,
        initEndDate: null
      }
    },
    props: {
      dateType: String,
      colVal: null,
      colId: null,
      updatePath: null,
      startTime: null,
      endTime: null,
      editingField: false,
      canEdit: { type: Boolean, default: false }

    },
    computed: {
      editableClassName() {
        const className = 'border-solid border-[1px] py-2 px-3 sci-cursor-edit'
        if (this.canEdit && this.errorMessage) return `${className} border-sn-delete-red`;
        if (this.canEdit && this.isEditing) return `${className} border-sn-science-blue`;
        if (this.canEdit) return `${className} border-sn-light-grey hover:border-sn-sleepy-grey`;
        return ''
      }
    },
    mounted() {
      this.cellUpdatePath = this.updatePath;
      this.values = this.colVal || {};
      this.timeFrom = this.startTime
      this.timeTo = this.endTime
      this.errorMessage = null;
      this.setParams();
      this.initDate = this.colVal?.datetime;
      this.initStartDate = this.startTime?.datetime;
      this.initEndDate = this.endTime?.datetime;
    },
    watch: {
      isEditing(newValue) {
        if (!newValue) return;
        // Focus input field to open date picker
        this.$nextTick(() => {
          $(this.$refs.edit)?.find('input')[0]?.focus();
        })
      }
    }
  }
</script>
