<template>
  <template v-if="params.dtComponent.currentViewRender === 'table'">
  <div class="group relative flex items-center group-hover:marker text-xs h-full w-full leading-[unset]">
    <div class="flex gap-2 w-full items-center text-sm leading-[unset]">
      <span class="cursor-pointer line-clamp-1 leading-[unset]"
            @click.stop="showDescriptionModal"
            v-html="params.data.sa_description">
      </span>
      <span @click.stop="showDescriptionModal" class="text-sn-blue cursor-pointer shrink-0 inline-block text-sm">
        {{ i18n.t('experiments.card.more') }}
      </span>
    </div>
  </div>
  </template>
  <template v-else>
    <div class="group relative flex items-center group-hover:marker text-xs h-full w-full">
      <div class="flex gap-2 w-full items-end text-xs">
        <span v-if="shouldTruncateText"
              class="cursor-pointer grow line-clamp-2"
              @click.stop="showDescriptionModal"
              v-html="params.data.sa_description">
        </span>
        <span v-else class="grow" v-html="params.data.sa_description"></span>
        <span v-if="shouldTruncateText" @click.stop="showDescriptionModal" class="text-sn-blue cursor-pointer shrink-0 inline-block text-xs">
          {{ i18n.t('experiments.card.more') }}
        </span>
      </div>
    </div>
  </template>
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
      return this.params.data.description?.length > 60;
    }
  },
  methods: {
    showDescriptionModal() {
      this.params.dtComponent.$emit('showDescription', null, [this.params.data]);
    },
  },
};
</script>
