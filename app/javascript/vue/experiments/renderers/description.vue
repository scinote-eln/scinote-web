<template>
  <div class="group leading-5 relative line-clamp-2 group-hover:marker" :class="{'cursor-pointer': showMoreButton}">
    {{ params.data.description }}
    <div v-if="showMoreButton" @click.stop="showMore"
         class="opacity-0 group-hover:opacity-100 text-xs text-sn-blue absolute bottom-0 right-0
                p-0.5 pl-8 bg-gradient-to-r from-transparent from-0% to-sn-super-light-grey to-30%">
      {{ i18n.t('experiments.card.more') }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'DescriptionRenderer',
  props: {
    params: {
      required: true,
    },

  },
  computed: {
    showMoreButton() {
      return this.params.data.description.length > 80;
    },
  },
  methods: {
    showMore() {

    },
  },
};
</script>
