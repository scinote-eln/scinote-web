<template>
  <div >
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
          <span @click.stop="showTextCellModal" class="text-sn-grey cursor-pointer shrink-0 inline-block text-sm leading-[unset]">
            {{ i18n.t('repositories.table.text.add_text') }}
          </span>
        </template>
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
    hasValue() {
      return this.sanitizedTextValue.length > 0 || this.textValue.length > 0;
    },
    sanitizedTextValue() {
      return this.params?.value?.value?.view_sanitized || '';
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

      this.params.dtComponent.$emit('showTextCell', null, [this.params.data], this.params.colDef);
    }
  }
};
</script>
