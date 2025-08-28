<template>
  <div class="w-full h-10 flex items-center">
    <GeneralDropdown>
      <template v-slot:field>
        <div
          class="h-6 w-6 border border-solid border-transparent rounded relative flex items-center justify-center text-sn-white"
          :style="{ backgroundColor: activeColor}"
        >
          a
        </div>
      </template>
      <template v-slot:flyout>
        <div class="grid grid-cols-4 gap-1">
          <div v-for="color in colors" :key="color"
              class="h-6 w-6 rounded relative flex items-center justify-center text-sn-white cursor-pointer"
              @click.stop="changeColor(color)"
              :style="{ backgroundColor: color }">
            <i v-if="color == activeColor" class="sn-icon sn-icon-check"></i>
            <span v-else>a</span>
          </div>
        </div>
      </template>
    </GeneralDropdown>
  </div>
</template>

<script>
import GeneralDropdown from '../../shared/general_dropdown.vue';

export default {
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  components: {
    GeneralDropdown
  },
  data() {
    return {
      colors: this.params.colors,
      activeColor: this.params.data.color
    };
  },
  methods: {
    changeColor(color) {
      if (this.params.data.id) {
        this.params.dtComponent.$emit('changeColor', color, this.params.data);
      } else {
        this.activeColor = color;
        this.params.dtComponent.setTemplateValue(color, 'color', true);
      }
    }
  }
};
</script>
