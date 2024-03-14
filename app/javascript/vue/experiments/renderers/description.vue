<template>
  <div class="group relative flex items-center group-hover:marker text-xs">
    <div class="flex items-end gap-2">
      <span v-if="shouldTruncateText"
            class="cursor-pointer grow"
            :class="{
              'line-clamp-1': params.dtComponent.currentViewRender === 'table',
              'line-clamp-2': params.dtComponent.currentViewRender === 'cards'
            }"
            @click.stop="showDescriptionModal"
            v-html="params.data.sa_description">
      </span>
      <span v-else class="grow" v-html="params.data.sa_description"></span>
      <span v-if="shouldTruncateText" @click.stop="showDescriptionModal" class="text-sn-blue cursor-pointer shrink-0 text-sm">{{ i18n.t('experiments.card.more') }}</span>
    </div>
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
  computed: {
    shouldTruncateText() {
      return this.params.data.description?.length > 80;
    }
  },
  methods: {
    showDescriptionModal() {
      this.params.dtComponent.$emit('showDescription', null, [this.params.data]);
    },
  },
};
</script>
