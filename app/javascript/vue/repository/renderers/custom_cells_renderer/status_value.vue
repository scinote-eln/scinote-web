<template>
  <div>
    <div v-if="params.data.permissions.manage" class="relative">
      <SelectDropdown
        class="h-10 flex w-full"
        :options="options"
        :borderless="true"
        :clearable="true"
        :labelRenderer="optionRenderer"
        :optionRenderer="optionRenderer"
        size="sm"
        :value="statusValue"
        @change="changeValue"
      />
    </div>
    <div v-else>
      <div ref="container" class="flex items-center gap-1">
        <span>{{ selectedOption[2].icon }}</span>
        <span>{{ selectedOption[1] }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import twemoji from 'twemoji';
import SelectDropdown from '../../../shared/select_dropdown.vue';
import optionRenderer from './option_renderer/status.vue';

export default {
  name: 'StatusValue',
  props: {
    params: {
      required: true
    }
  },
  components: {
    SelectDropdown,
    optionRenderer
  },
  computed: {
    options() {
      return this.params.colDef.cellRendererParams.columnItems.map(item => ([
        item.id, item.label, { icon: item.icon }
      ]));
    },
    selectedOption() {
      return this.options.find(option => option[0] === this.statusValue);
    },
    optionRenderer() {
      return optionRenderer;
    }
  },
  created() {
    this.statusValue = this.params?.value?.value?.id;
  },
  mounted() {
    this.renderEmoji();
  },
  data: () => ({
    statusValue: null
  }),
  methods: {
    renderEmoji() {
      twemoji.size = '24x24';
      twemoji.base = '/images/twemoji/';
      if (this.$refs.container) {
        twemoji.parse(this.$refs.container);
      }
    },
    changeValue(newValue) {
      this.statusValue = newValue;

      this.params.dtComponent.$emit(
        'updateCell',
        this.params.data,
        this.params.colDef,
        newValue
      );

      this.renderEmoji();
    }
  }
};
</script>
