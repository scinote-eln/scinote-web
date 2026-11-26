<template>
  <div :title="mandatoryErrorTitle">
    <div class="group relative flex items-center group-hover:marker text-xs h-full w-full leading-[unset]">
      <div ref="descripitonBox" class="flex gap-1 w-full items-center text-sm leading-[unset]">
        <template v-if="hasValue">
          <span v-if="sanitizedTextValue"
                class="cursor-pointer line-clamp-1 leading-[unset] truncate grow"
                @click="showTextCellModal"
                v-html="sanitizedTextValue">
          </span>
          <span v-else
                class="cursor-pointer line-clamp-1 leading-[unset] truncate grow"
                @click="showTextCellModal">
            {{ textValue }}
          </span>
          <div v-if="canManage"
               class="tw-hidden group-hover:block shrink-0 cursor-pointer"
               :title="i18n.t('general.edit')"
               @click.stop="showTextCellModal">
            <i class="sn-icon sn-icon-edit"></i>
          </div>
        </template>
        <template v-else-if="canManage">
          <span @click.stop="showTextCellModal"
                class="text-sn-grey cursor-pointer shrink-0 inline-block text-sm leading-[unset]"
                :class="addTextClass">
            {{ i18n.t('repositories.table.text.add_text') }}
          </span>
        </template>
      </div>
      <MandatoryError :show="params.inSidebar && showError" />
    </div>
  </div>
</template>

<script>
import MandatoryError from './shared/mandatory_error.vue';
import mandatoryCellMixin from './mixins/mandatory_cell.js';

export default {
  name: 'TextCellRenderer',
  mixins: [mandatoryCellMixin],
  components: {
    MandatoryError
  },
  props: {
    params: {
      required: true
    }
  },
  mounted() {
    window.renderElementSmartAnnotations(this.$refs.descripitonBox, 'span');
  },
  computed: {
    textValue() {
      return this.params?.value?.value?.edit || '';
    },
    hasValue() {
      return this.sanitizedTextValue.length > 0 || this.textValue.length > 0;
    },
    sanitizedTextValue() {
      return this.params?.value?.value?.view_sanitized || '';
    },
    isEmpty() {
      return this.textValue.trim() === '';
    },
    addTextClass() {
      if (!this.showError) return null;

      return [
        'border border-solid !border-sn-delete-red rounded',
        this.params.inSidebar ? 'px-3 py-2' : 'h-10 flex items-center px-1'
      ];
    },
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    }
  },
  methods: {
    showTextCellModal(e) {
      // handle smart annotations
      if (['atwho-user-popover', 'sa-name', 'sa-link', 'atwho-inserted'].some((c) => e.target.classList.contains(c))) {
        return;
      }

      this.touch();
      this.params.dtComponent.$emit('showTextCell', null, [this.params.data], this.params.colDef);
    }
  }
};
</script>
