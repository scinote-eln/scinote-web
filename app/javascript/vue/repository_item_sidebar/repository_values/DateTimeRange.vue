<template>
  <div>
    <div 
      v-click-outside="{ handler: 'validateAndSave', exclude: ['edit', 'view'] }"
      :class="`border-solid border-[1px] text-sn-dark-grey font-inter text-sm font-normal leading-5 w-full rounded relative sci-cursor-edit ${ borderColor }`"
    >
      <div v-if="dateType === 'date'" @click="enableEdit" class="p-2">
        <div v-if="isEditing || values?.datetime" ref="edit">
          <DateTimePicker
            @change="formatDateTime($event)"
            :selectorId="`DatePicker${colId}`"
            :dateOnly="true"
            :defaultValue="dateValue(values?.datetime)"
            :standAlone="true"
          />
        </div>
        <div v-else ref="view" >
          {{ i18n.t('repositories.item_card.repository_date_value.no_date') }}
        </div>
      </div>
      <div v-else-if="dateType === 'dateRange'" @click="enableEdit" class="p-2">
        <div v-if="isEditing || (timeFrom?.datetime && timeTo?.datetime)" ref="edit" class="w-full flex align-center">
          <div>
            <DateTimePicker
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
            @change="formatDateTime($event, 'end_time')"
            :selectorId="`DatePickerEnd${colId}`"
            :dateOnly="true"
            :defaultValue="dateValue(timeTo?.datetime)"
            :standAlone="true"
            :dateClassName="hasMonthText() ? 'w-[135px]' : 'w-[90px]'"
            />
          </div>
        </div>
        <div v-else ref="view" >
          {{ i18n.t('repositories.item_card.repository_date_range_value.no_date_range') }}
        </div>
      </div>
      <div v-if="dateType === 'dateTime'"  @click="enableEdit" class="p-2">
        <div v-if="isEditing || values?.datetime" ref="edit" class="w-full">
          <DateTimePicker
            @change="formatDateTime"
            :selectorId="`DatePicker${colId}`"
            :defaultValue="dateValue(values?.datetime)"
            :standAlone="true"
            :dateClassName="hasMonthText() ? 'w-[135px]' : 'w-[90px]'"
            timeClassName="w-11"
          />
        </div>
        <div v-else ref="view" >
          {{ i18n.t('repositories.item_card.repository_date_time_value.no_date_time') }}
        </div>
      </div>
      <div v-else-if="dateType === 'dateTimeRange'"  @click="enableEdit" class="p-2">
        <div v-if="isEditing || (timeFrom?.datetime && timeTo?.datetime)" ref="edit" class="w-full flex">
          <div>
            <DateTimePicker
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
              @change="formatDateTime($event, 'end_time')"
              :selectorId="`DatePickerEnd${colId}`"
              :defaultValue="dateValue(timeTo?.datetime)"
              :timeOnly="false"
              :dateOnly="false"
              :standAlone="true"
              :dateClassName="hasMonthText() ? 'w-[135px]' : 'w-[90px]'"
              timeClassName="w-11"
            />
          </div>
        </div>
        <div v-else ref="view" >
          {{ i18n.t('repositories.item_card.repository_date_time_range_value.no_date_time_range') }}
        </div>
      </div>
      <div v-else-if="dateType === 'time'" @click="enableEdit" class="p-2">
        <div v-if="isEditing || values?.datetime" ref="edit">
          <DateTimePicker
            @change="formatDateTime"
            :selectorId="`DatePicker${colId}`"
            :timeOnly="true"
            :defaultValue="dateValue(values?.datetime)"
            :standAlone="true"
            timeClassName="w-11"
          />
        </div>
        <div v-else ref="view">
          {{ i18n.t('repositories.item_card.repository_time_value.no_time') }}
        </div>
      </div>
      <div v-else-if="dateType === 'timeRange'" @click="enableEdit" class="p-2">
        <div v-if="isEditing || (timeFrom?.datetime && timeTo?.datetime)" ref="edit" class="w-full flex">
          <div>
            <DateTimePicker
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
              @change="formatDateTime($event, 'end_time')"
              :selectorId="`DatePickerEnd${colId}`"
              :timeOnly="true"
              :defaultValue="dateValue(timeTo?.datetime)"
              :standAlone="true"
              timeClassName="w-11"
            />
          </div>
        </div>
        <div v-else ref="view">
          {{ i18n.t('repositories.item_card.repository_time_range_value.no_time_range') }}
        </div>
      </div>
      <span class="absolute right-2 top-1.5" v-if="values.reminder">
        <Reminder :value="values" />
      </span>
    </div>
    <div class="text-sn-delete-red text-xs w-full " :class="{ visible: errorMessage, invisible: !errorMessage }">
      {{ errorMessage }}
    </div>
  </div>
</template>

<script>
  import outsideClick from './../../../packs/vue/directives/outside_click';
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
      'click-outside': outsideClick
    },
    data() {
      return {
        values: {},
        errorMessage: null,
        params: null,
        cellUpdatePath: null,
        timeFrom: null,
        timeTo: null,
        isEditing: false
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
    },
    mounted() {
      this.cellUpdatePath = this.updatePath;
      this.values = this.colVal || {};
      this.timeFrom = this.startTime
      this.timeTo = this.endTime
      this.errorMessage = null;
      this.setParams();
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
