<template>
  <div ref="container">
    <label class="sci-label">{{ i18n.t('libraries.manange_modal_column.status_type.status_options_label') }}</label>
    <div class="flex flex-col gap-2 mt-2">
      <div v-for="(item, index) in items" :key="item.id || `new-${index}`" class="flex items-center gap-2">
        <div class="status-item-icon cursor-pointer w-11 h-11 shrink-0 flex items-center justify-center border border-solid border-sn-sleepy-grey rounded"
             @click="openPicker(item, $event)"
        >
          <i v-if="!item.icon" class="fas fa-exclamation-circle text-sn-grey"></i>
          <div v-else v-html="renderIcon(item.icon)"></div>
        </div>
        <InputField
          v-model="item.status"
          :placeholder="i18n.t('libraries.manange_modal_column.name_placeholder')"
          class="grow"
        />
        <i class="sn-icon sn-icon-delete cursor-pointer" @click="removeItem(index)"></i>
      </div>
    </div>
    <div class="flex items-center justify-center gap-2 cursor-pointer mt-3 pb-3 border-sn-light-grey text-sn-blue"
         @click="addItem" data-e2e="e2e-BT-invItems-manageColumns-statusOption-add">
      <i class="sn-icon sn-icon-new-task"></i>
      <span>{{ i18n.t('libraries.manange_modal_column.status_type.add_status_label') }}</span>
    </div>
    <div class="mt-4 p-4 rounded bg-sn-super-light-grey">
      <label class="sci-label font-bold">{{ i18n.t('general.preview') }}</label>
      <div class="mt-2">
        <SelectDropdown
          class="bg-sn-white"
          :options="previewOptions"
          :optionRenderer="StatusOptionRenderer"
          :labelRenderer="StatusOptionRenderer"
          :clearable="true" />
      </div>
    </div>
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS */
import twemoji from 'twemoji';
import { EmojiButton } from '@joeattardi/emoji-button';
import InputField from '../../../../shared/input_field.vue';
import SelectDropdown from '../../../../shared/select_dropdown.vue';
import StatusOptionRenderer from '../../../renderers/custom_cells_renderer/option_renderer/status.vue';

export default {
  name: 'StatusColumnType',
  components: { InputField, SelectDropdown },
  props: {
    column: { type: Object, default: null }
  },
  data() {
    const items = (this.column?.cellRendererParams?.columnItems || []).map((i) => (
      { id: i.id, status: i.icon && i.label.startsWith(i.icon) ? i.label.slice(i.icon.length).trim() : i.label, icon: i.icon }
    ));
    return {
      items: items.length > 0 ? items : [{ id: null, status: '', icon: null }],
      removedIds: []
    };
  },
  computed: {
    StatusOptionRenderer: () => StatusOptionRenderer,
    previewOptions() {
      return this.items.map((item, index) => [item.id ?? `new-${index}`, `${item.icon || ''} ${item.status}`.trim()]);
    }
  },
  methods: {
    renderIcon(icon) {
      if (!icon) return '';
      return twemoji.parse(icon, { base: '/images/twemoji/', size: '24x24' });
    },
    addItem() {
      this.items.push({ id: null, status: '', icon: null });
    },
    removeItem(index) {
      const [item] = this.items.splice(index, 1);
      if (item.id) this.removedIds.push(item.id);
    },
    openPicker(item, event) {
      const picker = new EmojiButton({ rootElement: this.$refs.container });
      picker.on('emoji', (emoji) => {
        item.icon = emoji.emoji;
      });
      picker.showPicker(event.currentTarget);
    },
    valid() {
      return this.items.length > 0 && this.items.every((item) => (
        !!item.icon &&
        item.status.trim().length >= GLOBAL_CONSTANTS.NAME_MIN_LENGTH &&
        item.status.trim().length <= GLOBAL_CONSTANTS.NAME_MAX_LENGTH
      ));
    },
    payload() {
      const attributes = this.items.map((item) => (
        item.id ? { id: item.id, status: item.status, icon: item.icon } : { status: item.status, icon: item.icon }
      ));
      this.removedIds.forEach((id) => attributes.push({ id, _destroy: true }));
      return { repository_status_items_attributes: attributes };
    }
  }
};
</script>
