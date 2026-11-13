<template>
  <div>
    <div class="group relative flex gap-1 w-full text-sm"
         :class="wrapped ? 'items-start py-2.5 leading-5' : 'items-center h-full max-h-10 leading-[unset]'">
      <div ref="descripitonBox" class="min-w-0 grow">
        <template v-if="sanitizedTextValue && sanitizedTextValue.length > 0">
          <span class="cursor-pointer"
                :class="textClasses"
                @click.stop v-html="sanitizedTextValue">
          </span>
        </template>
        <template v-else-if="textValue && textValue.length > 0">
          <span class="cursor-pointer"
                :class="textClasses"
                @click="showTextCellModal">
            {{ textValue }}
          </span>
        </template>
        <template v-else-if="canManage">
          <span @click.stop="showTextCellModal"
                class="text-sn-grey cursor-pointer inline-block"
                data-e2e="e2e-BT-invItems-textCell-addText">
            {{ i18n.t('repositories.table.text.add_text') }}
          </span>
        </template>
      </div>
      <div v-if="hasText && canManage"
           class="shrink-0 tw-hidden group-hover:block"
           :title="i18n.t('general.edit')"
           data-e2e="e2e-BT-invItems-textCell-edit"
           @click.stop="showTextCellModal">
        <i class="sn-icon sn-icon-edit cursor-pointer"></i>
      </div>
    </div>
  </div>
</template>

<script>

export default {
  name: 'TextCellRenderer',
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
    sanitizedTextValue() {
      return this.params?.value?.value?.view_sanitized || '';
    },
    hasText() {
      return this.sanitizedTextValue.length > 0 || this.textValue.length > 0;
    },
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    },
    wrapped() {
      return !!this.params?.colDef?.wrapText;
    },
    textClasses() {
      return this.wrapped ? 'block whitespace-pre-wrap break-words' : 'block truncate';
    }
  },
  methods: {
    showTextCellModal(e) {
      // handle smart annotations
      if (['atwho-user-popover', 'sa-name', 'sa-link', 'atwho-inserted'].some((c) => e.target.classList.contains(c))) {
        return;
      }

      this.params.dtComponent.$emit('showTextCell', null, [this.params.data], this.params.colDef);
    }
  }
};
</script>
