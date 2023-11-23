<template>
  <div>
    <div
      ref="dateTimeRangeOverlay"
      class="fixed top-0 left-0 right-0 bottom-0 bg-transparent z-[999] hidden"
    ></div>
    <div
      @click="enableEdit"
      v-click-outside="validateAndSave"
      class="text-sn-dark-grey font-inter text-sm font-normal leading-5 w-full rounded relative !px-2 !py-0
             min-h-[32px] flex items-center
             [&_.dp\_\_input]:border-0 [&_.dp\_\_input]:p-0"
      :class="editableClassName"
    >
      <template v-if="dateType === 'date'">
        <div
          v-if="isEditing || values?.datetime"
          ref="edit"
          class="[&_.dp\_\_input]:!w-20"
        >
          <DateTimePicker
            :mode="'date'"
            :disabled="!canEdit"
            @change="formatDateTime($event)"
            @open="enableEdit"
            @close="validateAndSave"
            :inputIconHidden="true"
            inputClassName="sci-cursor-edit"
            :selectorId="`DatePicker${colId}`"
            :defaultValue="dateValue(values?.datetime)"
            :placeholder="
              i18n.t('repositories.item_card.repository_date_value.placeholder')
            "
          />
        </div>
        <div
          v-else
          ref="view"
          :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }"
        >
          {{
            i18n.t(
              `repositories.item_card.repository_date_value.${
                canEdit ? "placeholder" : "no_date"
              }`
            )
          }}
        </div>
      </template>
      <template v-else-if="dateType === 'dateRange'">
        <div
          v-if="isEditing || (timeFrom?.datetime && timeTo?.datetime)"
          ref="edit"
          class="w-full flex align-center [&_.dp\_\_input]:!w-20"
        >
          <div>
            <DateTimePicker
              :mode="'date'"
              :disabled="!canEdit"
              @change="formatDateTime($event, 'start_time')"
              @open="enableEdit"
              @close="validateAndSave"
              :inputIconHidden="true"
              inputClassName="sci-cursor-edit"
              :selectorId="`DatePickerStart${colId}`"
              :defaultValue="dateValue(timeFrom?.datetime)"
              :placeholder="
                i18n.t(
                  'repositories.item_card.repository_date_range_value.placeholder'
                )
              "
            />
          </div>
          <span class="flex items-center mx-1">-</span>
          <div>
            <DateTimePicker
              :mode="'date'"
              :disabled="!canEdit"
              @change="formatDateTime($event, 'end_time')"
              @open="enableEdit"
              @close="validateAndSave"
              :inputIconHidden="true"
              inputClassName="sci-cursor-edit"
              :selectorId="`DatePickerEnd${colId}`"
              :defaultValue="dateValue(timeTo?.datetime)"
              :placeholder="
                i18n.t(
                  'repositories.item_card.repository_date_range_value.placeholder'
                )
              "
            />
          </div>
        </div>
        <div
          v-else
          ref="view"
          :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }"
        >
          {{
            i18n.t(
              `repositories.item_card.repository_date_range_value.${
                canEdit ? "placeholder" : "no_date_range"
              }`
            )
          }}
        </div>
      </template>
      <template v-if="dateType === 'dateTime'">
        <div
          v-if="isEditing || values?.datetime"
          ref="edit"
          class="w-full [&_.dp\_\_input]:!w-[7.125rem]"
        >
          <DateTimePicker
            :mode="'datetime'"
            :disabled="!canEdit"
            @change="formatDateTime"
            @open="enableEdit"
            @close="validateAndSave"
            :inputIconHidden="true"
            inputClassName="sci-cursor-edit"
            :selectorId="`DatePicker${colId}`"
            :defaultValue="dateValue(values?.datetime)"
            :placeholder="
              i18n.t(
                'repositories.item_card.repository_date_time_value.placeholder'
              )
            "
          />
        </div>
        <div
          v-else
          ref="view"
          :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }"
        >
          {{
            i18n.t(
              `repositories.item_card.repository_date_time_value.${
                canEdit ? "placeholder" : "no_date_time"
              }`
            )
          }}
        </div>
      </template>
      <template v-else-if="dateType === 'dateTimeRange'">
        <div
          v-if="isEditing || (timeFrom?.datetime && timeTo?.datetime)"
          ref="edit"
          class="w-full flex [&_.dp\_\_input]:!w-[7.125rem]"
        >
          <div>
            <DateTimePicker
              :mode="'datetime'"
              :disabled="!canEdit"
              @change="formatDateTime($event, 'start_time')"
              @open="enableEdit"
              @close="validateAndSave"
              :inputIconHidden="true"
              inputClassName="sci-cursor-edit"
              :selectorId="`DatePickerStart${colId}`"
              :defaultValue="dateValue(timeFrom?.datetime)"
              :timeOnly="false"
              :dateOnly="false"
              :placeholder="
                i18n.t(
                  'repositories.item_card.repository_date_time_range_value.placeholder'
                )
              "
            />
          </div>
          <span class="flex items-center mx-1">-</span>
          <div>
            <DateTimePicker
              :mode="'datetime'"
              :disabled="!canEdit"
              @change="formatDateTime($event, 'end_time')"
              @open="enableEdit"
              @close="validateAndSave"
              :inputIconHidden="true"
              inputClassName="sci-cursor-edit"
              :selectorId="`DatePickerEnd${colId}`"
              :defaultValue="dateValue(timeTo?.datetime)"
              :timeOnly="false"
              :dateOnly="false"
              :placeholder="
                i18n.t(
                  'repositories.item_card.repository_date_time_range_value.placeholder'
                )
              "
            />
          </div>
        </div>
        <div
          v-else
          ref="view"
          :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }"
        >
          {{
            i18n.t(
              `repositories.item_card.repository_date_time_range_value.${
                canEdit ? "placeholder" : "no_date_time_range"
              }`
            )
          }}
        </div>
      </template>
      <template v-else-if="dateType === 'time'">
        <div
          v-if="isEditing || values?.datetime"
          ref="edit"
          class="[&_.dp\_\_input]:!w-10"
        >
          <DateTimePicker
            :mode="'time'"
            :disabled="!canEdit"
            @change="formatDateTime"
            @open="enableEdit"
            @close="validateAndSave"
            :inputIconHidden="true"
            inputClassName="sci-cursor-edit"
            :selectorId="`DatePicker${colId}`"
            :defaultValue="dateValue(values?.datetime)"
            :placeholder="
              i18n.t('repositories.item_card.repository_time_value.placeholder')
            "
          />
        </div>
        <div
          v-else
          ref="view"
          :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }"
        >
          {{
            i18n.t(
              `repositories.item_card.repository_time_value.${
                canEdit ? "placeholder" : "no_time"
              }`
            )
          }}
        </div>
      </template>
      <template v-else-if="dateType === 'timeRange'">
        <div
          v-if="isEditing || (timeFrom?.datetime && timeTo?.datetime)"
          ref="edit"
          class="w-full flex [&_.dp\_\_input]:!w-10"
        >
          <div>
            <DateTimePicker
              :mode="'time'"
              :disabled="!canEdit"
              @change="formatDateTime($event, 'start_time')"
              @open="enableEdit"
              @close="validateAndSave"
              :inputIconHidden="true"
              inputClassName="sci-cursor-edit"
              :selectorId="`DatePickerStart${colId}`"
              :defaultValue="dateValue(timeFrom?.datetime)"
              :placeholder="
                i18n.t(
                  'repositories.item_card.repository_time_range_value.placeholder'
                )
              "
            />
          </div>
          <span class="flex items-center mx-1">-</span>
          <div>
            <DateTimePicker
              :mode="'time'"
              :disabled="!canEdit"
              @change="formatDateTime($event, 'end_time')"
              @open="enableEdit"
              @close="validateAndSave"
              :inputIconHidden="true"
              inputClassName="sci-cursor-edit"
              :selectorId="`DatePickerEnd${colId}`"
              :defaultValue="dateValue(timeTo?.datetime)"
              :placeholder="
                i18n.t(
                  'repositories.item_card.repository_time_range_value.placeholder'
                )
              "
            />
          </div>
        </div>
        <div
          v-else
          ref="view"
          :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }"
        >
          {{
            i18n.t(
              `repositories.item_card.repository_time_range_value.${
                canEdit ? "placeholder" : "no_time_range"
              }`
            )
          }}
        </div>
      </template>
      <span class="absolute right-2 top-1.5" v-if="values?.reminder">
        <Reminder :value="values" />
      </span>
    </div>
    <div
      class="text-sn-delete-red text-xs w-full "
      :class="{ visible: errorMessage, invisible: !errorMessage }"
    >
      {{ errorMessage }}
    </div>
  </div>
</template>

<script>
import { vOnClickOutside } from '@vueuse/components';
import dateTimeRange from '../mixins/date_time_range';
import DateTimePicker from '../../shared/date_time_picker.vue';
import Reminder from '../reminder.vue';

export default {
  name: 'DateTimeRange',
  mixins: [dateTimeRange],
  components: {
    DateTimePicker,
    Reminder,
  },
  directives: {
    'click-outside': vOnClickOutside,
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
      initEndDate: null,
    };
  },
  props: {
    dateType: String,
    colVal: null,
    colId: null,
    updatePath: null,
    startTime: null,
    endTime: null,
    editingField: false,
    canEdit: { type: Boolean, default: false },
  },
  computed: {
    editableClassName() {
      const className = 'border-solid border-[1px] py-2 px-3 sci-cursor-edit';
      if (this.canEdit && this.errorMessage) return `${className} border-sn-delete-red`;
      if (this.canEdit && this.isEditing) return `${className} border-sn-science-blue`;
      if (this.canEdit) return `${className} border-sn-light-grey hover:border-sn-sleepy-grey`;
      return '';
    },
  },
  mounted() {
    this.cellUpdatePath = this.updatePath;
    this.values = this.colVal || {};
    this.timeFrom = this.startTime;
    this.timeTo = this.endTime;
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
        $(this.$refs.edit)
          ?.find('input')[0]
          ?.focus();
      });
    }
  }
};
</script>
