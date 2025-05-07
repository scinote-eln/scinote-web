<template>
  <div v-if="hasFavorite">
    <button @click="updateFavorite(!favorite)"
            class="flex justify-center items-center w-full h-9 bg-transparent border-none cursor-pointer">
      <div v-if="favorite" class="sn-icon sn-icon-star-filled text-sn-alert-brittlebush"></div>
      <div v-else @mouseover="hovered = true"
                  @mouseleave="hovered = false">
        <div class="text-sn-grey-500 sn-icon" :class="{ 'sn-icon-star-filled': hovered, 'sn-icon-star': !hovered }"></div>
      </div>
    </button>
  </div>
</template>
<script>

export default {
  name: 'favoriteRenderer',
  props: {
    params: {
      required: true
    }
  },
  data() {
    return {
      favorite: false,
      hovered: false
    };
  },
  created() {
    this.favorite = this.params.data.favorite;
  },
  computed: {
    hasFavorite() {
      return this.params.data.favorite !== null;
    }
  },
  methods: {
    updateFavorite(value) {
      this.params.dtComponent.$emit('updateFavorite', value, this.params);
      this.favorite = value;
    }
  }
};
</script>
