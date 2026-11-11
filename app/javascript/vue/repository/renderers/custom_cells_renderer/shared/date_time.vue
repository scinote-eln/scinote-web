<template>
  <div>
    <div v-if="canManage" class="relative flex items-center gap-1" :title="!params.inSidebar && showError ? mandatoryError : null">
      <DateTimePicker
        :class="{ 'borderless-input -mt-[1px]': !params.inSidebar }"
        :error="showError"
        :defaultValue="value"
        @change="updateValue"
        @closed="saveValue"
        :mode="mode"
        :placeholder="placeholder"
        :customIcon="icon"
        :customIconTitle="hasReminder ? reminderTitle : null"
        :range="isRange"
        valueType="stringWithoutTimezone"
        :clearable="true"/>
      <div v-if="params.inSidebar && showError"
        class="absolute top-full left-0 w-full truncate text-xs text-sn-delete-red"
        data-e2e="e2e-TX-itemCard-mandatoryError">
        {{ mandatoryError }}
      </div>
    </div>
    <div v-else-if="params.value">
      <div v-if="isRange" class="flex items-center gap-1">
        {{ params.value.value.start_time.formatted }}
        <span> - </span>
        {{ params.value.value.end_time.formatted }}
      </div>
      <div v-else class="flex items-center gap-1">
        <i v-if="hasReminder"
          :class="reminderClass"
          :title="reminderTitle"
          class="sn-icon sn-icon-alert-warning shrink-0"></i>
        {{ params.value.value.formatted }}
      </div>
    </div>
  </div>
</template>

<script>
import DateTimePicker from '../../../../shared/date_time_picker.vue';

export default {
  name: 'DateTimeShared',
  props: {
    params: {
      required: true
    }
  },
  components: {
    DateTimePicker
  },
  created() {
    if (this.isRange) {
      if (this.params.value?.value?.start_time?.datetime && this.params.value?.value?.end_time?.datetime) {
        this.value = [
          this.params.value.value.start_time.datetime,
          this.params.value.value.end_time.datetime
        ];
      }
    } else {
      this.value = this.params.value?.value?.datetime;
    }
  },
  data() {
    return {
      value: null,
      touched: false
    };
  },
  computed: {
    mandatory() {
      const { isMandatory, mandatory } = this.params.colDef?.cellRendererParams || {};

      return isMandatory ? !!isMandatory() : !!mandatory;
    },
    isEmpty() {
      if (Array.isArray(this.value)) return !this.value[0] || !this.value[1];

      return !this.value;
    },
    showError() {
      return this.mandatory && this.touched && this.isEmpty;
    },
    mandatoryError() {
      return this.i18n.t('repositories.mandatory_column.field_error');
    },
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    },
    valueType() {
      return this.params.colDef.cellRendererParams.columnDataType;
    },
    isRange() {
      return this.valueType.includes('Range');
    },
    mode() {
      if (this.valueType.includes('RepositoryDateTime')) {
        return 'datetime';
      } else if (this.valueType.includes('RepositoryDate')) {
        return 'date';
      } else if (this.valueType.includes('RepositoryTime')) {
        return 'time';
      }
    },
    placeholder() {
      if (this.valueType.includes('RepositoryDate')) {
        if (this.isRange) {
          return this.i18n.t('repositories.table.date_time.add_date_range');
        }
        return this.i18n.t('repositories.table.date_time.add_date')
      } else if (this.valueType.includes('RepositoryTime')) {
        if (this.isRange) {
          return this.i18n.t('repositories.table.date_time.add_time_range');
        }
        return this.i18n.t('repositories.table.date_time.add_time')
      }
    },
    icon() {
      if (this.hasReminder) {
        return `sn-icon sn-icon-alert-warning ${this.reminderClass}`;
      }

      if (this.valueType.includes('RepositoryTime')) {
        return 'sn-icon sn-icon-created';
      } else {
        return 'sn-icon sn-icon-calendar';
      }
    },
    hasReminder() {
      return !this.isRange && !!this.params.value?.value?.reminder;
    },
    reminderClass() {
      return this.params.value?.value?.days_left > 0 ? 'text-sn-alert-brittlebush' : 'text-sn-alert-passion';
    },
    reminderTitle() {
      const cellValue = this.params.value?.value;

      return [cellValue?.reminder_text, cellValue?.reminder_message].filter(Boolean).join('\n');
    }
  },
  methods: {
    updateValue(newValue) {
      this.value = newValue;

      if (this.value == '' || this.value == null) {
        this.saveValue();
      }
    },
    saveValue() {
      this.touched = true;
      if (this.showError && this.params.data?.id) return;

      let valueToSend;

      if (this.isRange) {
        valueToSend = {
          start_time: this.value[0],
          end_time: this.value[1]
        };
      } else {
        valueToSend = this.value;
      }

      this.params.dtComponent.$emit(
        'updateCell',
        this.params.data,
        this.params.colDef,
        valueToSend
      );
    }
  }
};
</script>
