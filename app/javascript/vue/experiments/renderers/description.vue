<template>
  <div class="group relative flex items-center group-hover:marker text-xs h-full w-full"
       :style="{ lineHeight: 'unset' }">
    <div class="flex gap-2 w-full"
        :style="{ lineHeight: 'unset' }"
        :class="{
                  'items-center text-sm': params.dtComponent.currentViewRender === 'table',
                  'items-end text-xs': params.dtComponent.currentViewRender === 'cards'
                }">
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
      <span v-if="shouldTruncateText" @click.stop="showDescriptionModal" class="text-sn-blue cursor-pointer shrink-0 inline-block"
            :style="{ lineHeight: 'unset' }"
            :class="{
                      'text-xs': params.dtComponent.currentViewRender === 'cards',
                      'text-sm': params.dtComponent.currentViewRender === 'table'
                    }">
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
