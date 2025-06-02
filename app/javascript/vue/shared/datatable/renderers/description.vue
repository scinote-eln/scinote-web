<template>
  <div v-if="!params.data.folder">
    <template v-if="params.dtComponent.currentViewRender === 'table'">
    <div class="group relative flex items-center group-hover:marker text-xs h-full w-full leading-[unset]">
      <div ref="descripitonBox" class="flex gap-2 w-full items-center text-sm leading-[unset]">
        <span v-if="params.data.description && removeTags(params.data.description).length > 0" class="cursor-pointer line-clamp-1 leading-[unset]"
              @click.stop="showDescriptionModal">
          {{ removeTags(params.data.description) }}
        </span>
        <span v-if="params.data.description && params.data.description.length > 0"
              @click.stop="showDescriptionModal"
              class="text-sn-blue cursor-pointer shrink-0 inline-block text-sm leading-[unset]">
          {{ i18n.t('experiments.card.more') }}
        </span>
        <span v-else-if="params.data.permissions.manage" @click.stop="showDescriptionModal" class="text-sn-blue cursor-pointer shrink-0 inline-block text-sm leading-[unset]">
          {{ i18n.t('experiments.card.add_description') }}
        </span>
      </div>
    </div>
    </template>
    <template v-else>
      <div class="group relative flex items-center group-hover:marker text-xs h-full w-full">
        <div ref="descripitonBox" class="flex gap-2 w-full items-end text-xs">
          <span v-if="shouldTruncateText"
                class="cursor-pointer grow line-clamp-2"
                @click.stop="showDescriptionModal">
            {{ removeTags(params.data.description) }}
          </span>
          <span v-else class="grow">{{ removeTags(params.data.description) }}</span>
          <span v-if="shouldTruncateText" @click.stop="showDescriptionModal" class="text-sn-blue cursor-pointer shrink-0 inline-block text-xs">
            {{ i18n.t('experiments.card.more') }}
          </span>
        </div>
      </div>
    </template>
  </div>
</template>

<script>
export default {
  name: 'DescriptionRenderer',
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
    shouldTruncateText() {
      return this.params.data.description?.length > 60;
    }
  },
  methods: {
    showDescriptionModal() {
      this.params.dtComponent.$emit('showDescription', null, [this.params.data]);
    },
    removeTags(description) {
      const itemHtml = $(`<span>${description}</span>`);
      itemHtml.remove('table, img');
      const str = itemHtml.text().trim();
      return str.length > 56 ? `${str.slice(0, 56)}...` : str;
    }
  }
};
</script>
