<template>
  <div class="relative leading-5 h-full flex items-center">
    <div>
      {{ i18n.t(label, {
        completed: this.params.data[this.completedField],
        all: this.params.data[this.totalField]
      }) }}
      <div class="py-1">
        <div class="w-24 h-1 bg-sn-light-grey">
          <div class="h-full"
               :class="{
                 'bg-sn-black': params.data.archived_on,
                 'bg-sn-blue': !params.data.archived_on
               }"
               :style="{
                 width: `${progress}%`
               }"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CounterRenderer',
  props: {
    params: {
      required: true
    },
    totalField: String,
    completedField: String,
    label: String
  },
  computed: {
    progress() {
      const completedCounter = this.params.data[this.completedField];
      const totalCounter = this.params.data[this.totalField];

      if (totalCounter === 0) return 3;
      if (completedCounter === 0) return 3;

      return (completedCounter / totalCounter) * 100;
    }
  }
};
</script>
