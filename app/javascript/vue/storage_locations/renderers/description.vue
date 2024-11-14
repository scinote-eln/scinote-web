<template>
  <div v-if="params.data.sa_description" class="group relative flex items-center group-hover:marker text-xs h-full w-full leading-[unset]">
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
    }
  }
};
</script>
