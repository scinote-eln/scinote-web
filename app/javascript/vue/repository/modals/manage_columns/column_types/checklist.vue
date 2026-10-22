<template>
  <div class="flex flex-col gap-4">
    <div>
      <label class="sci-label">{{ i18n.t('libraries.manange_modal_column.list_type.delimiter_label') }}</label>
      <div class="mt-2">
        <SelectDropdown
          :value="delimiterKey"
          :options="delimiterOptions"
          :optionRenderer="DelimiterOption"
          :labelRenderer="DelimiterOption"
          :disabled="!!column"
          @change="delimiterKey = $event"
        />
      </div>
    </div>
    <ItemsEditor
      ref="itemsEditor"
      v-model="items"
      :limit="limit"
      :label="i18n.t('libraries.manange_modal_column.checklist_type.checklist_items')"
      :placeholder="placeholder"
      :delimiter="delimiterChar"
      :splitPattern="splitPattern"
      :isEditing="!!column"
      :multiple="true"
      :changeWarning="i18n.t('libraries.manange_modal_column.change_multi_select_items_warning')"
    />
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS */
import ItemsEditor from './items_editor.vue';
import SelectDropdown from '../../../../shared/select_dropdown.vue';
import DelimiterOption from './delimiter_option.vue';
import { DELIMITER_CHARS, delimiterOptions } from './delimiter_options.js';

const AUTO_SPLIT_PATTERN = /[\n,;]+/;

export default {
  name: 'ChecklistColumnType',
  components: { ItemsEditor, SelectDropdown },
  props: {
    column: { type: Object, default: null }
  },
  data() {
    return {
      limit: GLOBAL_CONSTANTS.REPOSITORY_CHECKLIST_ITEMS_PER_COLUMN,
      delimiterKey: this.column ? (this.column.cellRendererParams?.metadata?.delimiter || 'return') : 'auto',
      items: (this.column?.cellRendererParams?.columnItems || []).map((i) => i.label)
    };
  },
  computed: {
    DelimiterOption: () => DelimiterOption,
    delimiterOptions() {
      return delimiterOptions(this.i18n);
    },
    delimiterChar() {
      return DELIMITER_CHARS[this.delimiterKey];
    },
    splitPattern() {
      return this.delimiterKey === 'auto' ? AUTO_SPLIT_PATTERN : null;
    },
    placeholder() {
      return this.i18n.t(`libraries.manange_modal_column.checklist_type.items_placeholders.${this.delimiterKey}`);
    }
  },
  methods: {
    valid() {
      return this.$refs.itemsEditor.valid();
    },
    payload() {
      const payload = { repository_checklist_items_attributes: this.items.map((data) => ({ data })) };
      if (!this.column) payload.metadata = { delimiter: this.delimiterKey };
      return payload;
    }
  }
};
</script>
