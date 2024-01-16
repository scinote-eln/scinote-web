<template>
  <div class="group relative flex items-center group-hover:marker">
    <span v-if="shouldTruncateText"
          class="line-clamp-1 cursor-pointer"
          @click.stop="showDescriptionModal"
          v-html="params.data.sa_description">
    </span>
    <span v-else v-html="params.data.sa_description"></span>
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
    shouldTruncateText() {
      return this.params.data.description.length > 80;
    },
  },
  methods: {
    showDescriptionModal() {
      this.params.dtComponent.$emit('showDescription', null, [this.params.data]);
    },
  },
};
</script>
