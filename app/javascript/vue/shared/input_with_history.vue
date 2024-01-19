<template>
  <div>
    <label v-if="label" class="sci-label" :for="id">{{ label }}</label>
    <div class="sci-input-container-v2">

      <input :value="modelValue"
             :placeholder="placeholder"
             :id="id"
             type="text"
             autocomplete="off"
             class="sci-input-field"
             @focus="showHistory"
             @blur="hideHistory"
             @change="saveQuery"
             ref="input" />
      <div v-if="historyShown" class="absolute top-10 z-10 bg-white w-full sn-shadow-menu-sm p-4 history-flyout">
        <ul class="px-0 mb-0">
          <li v-for="(query, index) in previousQueries" :key="`query_${index}`"
              class="cursor-pointer list-none p-1.5 leading-8 truncate" @click="selectFromHistory(query)"
          >
            <i class="sn-icon sn-icon-created ml-1 mr-2.5 text-sn-grey"></i>
            {{ query }}
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'inputWithHistory',
  props: {
    label: { type: String },
    modelValue: { type: String },
    placeholder: { type: String },
    id: { type: String }
  },
  data() {
    return {
      previousQueries: [],
      historyShown: false
    };
  },
  mounted() {
    this.previousQueries = JSON.parse(localStorage.getItem(this.id) || '[]');
  },
  methods: {
    showHistory() {
      this.historyShown = true;
    },
    hideHistory() {
      setTimeout(() => {
        this.historyShown = false;
      }, 200);
    },
    selectFromHistory(value) {
      this.$emit('update:modelValue', value);
    },
    saveQuery(event) {
      const newValue = event.target.value;

      if (newValue == this.modelValue) return;

      if (newValue.length > 0) {
        this.previousQueries.push(newValue);

        if (this.previousQueries.length > 5) {
          this.previousQueries.shift();
        }

        localStorage.setItem(this.id, JSON.stringify(this.previousQueries));
      }
      this.$emit('update:modelValue', newValue);
    }
  }
};
</script>
