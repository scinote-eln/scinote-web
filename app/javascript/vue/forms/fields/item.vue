<template>
  <div>
    <button class="btn btn-secondary" @click="rowSelectorOpened = true"> {{  i18n.t('forms.show.select_items') }}</button>
    <RowSelectorModal v-if="rowSelectorOpened"
                      :repository="value.repository"
                      :rows="value.rows"
                      @close="rowSelectorOpened = false"
                      @save="saveValue" />
    {{ value }}
  </div>
</template>

<script>
/* global  */

import fieldMixin from './field_mixin';
import RowSelectorModal from './modals/row_selector.vue';

export default {
  name: 'ItemField',
  mixins: [fieldMixin],
  components: {
    RowSelectorModal
  },
  data() {
    return {
      value: {
        repository: null,
        rows: []
      },
      rowSelectorOpened: false
    };
  },
  watch: {
    marked_as_na() {
      if (this.marked_as_na) {
        this.value = null;
      }
    }
  },
  mounted() {
  },
  methods: {
    saveValue(repository, rows) {
      this.value = {
        repository,
        rows
      };
      this.rowSelectorOpened = false;
      //this.$emit('save', this.value);
    }
  },
  computed: {
    validValue() {
      return true;
    }
  }
};
</script>
