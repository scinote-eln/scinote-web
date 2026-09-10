<template>
  <div >
    <div class="group relative flex items-center group-hover:marker text-xs h-full w-full leading-[unset]">
      <div ref="descripitonBox" class="flex gap-2 w-full items-center text-sm leading-[unset]">
        <template v-if="sanitizedTextValue && sanitizedTextValue.length > 0">
          <span class="cursor-pointer line-clamp-1 leading-[unset]"
            @click.stop v-html="sanitizedTextValue">
          </span>
        </template>
        <template v-else-if="textValue && textValue.length > 0">
          <span class="cursor-pointer line-clamp-1 leading-[unset]"
                @click.stop="showTextCellModal">
            {{ textValue}}
          </span>
          <span @click.stop="showTextCellModal" class="text-sn-blue cursor-pointer shrink-0 inline-block text-sm leading-[unset]">
            {{ i18n.t('repositories.table.text.more') }}
          </span>
        </template>
        <template v-else-if="canManage">
          <span @click.stop="showTextCellModal" class="text-sn-blue cursor-pointer shrink-0 inline-block text-sm leading-[unset]">
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
    this.$nextTick(() => {
      window.renderElementSmartAnnotations(this.$refs.descripitonBox, 'span');
    });
  },
  computed: {
    textValue() {
      return this.params?.value?.value?.edit || '';
    },
    sanitizedTextValue() {
      return this.params?.value?.value?.view_sanitized || '';
    },
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    }
  },
  methods: {
    showTextCellModal() {
      this.params.dtComponent.$emit('showTextCell', null, [this.params.data], this.params.colDef);
    }
  }
};
</script>
