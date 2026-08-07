<template>
  <div>
    <div v-if="params.data.permissions.manage">
      <DateTimePicker
        class="borderless-input -mt-[1px]"
        :defaultValue="value"
        @change="updateValue"
        @closed="saveValue"
        :mode="mode"
        :customIcon="icon"
        :range="isRange"
        valueType="stringWithoutTimezone"
        :clearable="true"/>
    </div>
    <div v-else>
      <div v-if="isRange" class="flex items-center gap-1">
        {{ params.value.value.start_time.formatted }}
        <span> - </span>
        {{ params.value.value.end_time.formatted }}
      </div>
      <div v-else>
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
      this.value = [
        this.params.value?.value?.start_time?.datetime,
        this.params.value?.value?.end_time?.datetime
      ];
    } else {
      this.value = this.params.value?.value?.datetime;
    }
  },
  data() {
    return {
      value: null
    };
  },
  computed: {
    isRange() {
      return this.params.value.value_type.includes('Range');
    },
    mode() {
      if (this.params.value.value_type.includes('RepositoryDateTime')) {
        return 'datetime';
      } else if (this.params.value.value_type.includes('RepositoryDate')) {
        return 'date';
      } else if (this.params.value.value_type.includes('RepositoryTime')) {
        return 'time';
      }
    },
    icon() {
      if (this.params.value.value_type.includes('RepositoryTime')) {
        return 'sn-icon sn-icon-created';
      } else {
        return 'sn-icon sn-icon-calendar';
      }
    }
  },
  methods: {
    updateValue(newValue) {
      this.value = newValue;
    },
    saveValue() {
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
