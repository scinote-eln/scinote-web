<template>
  <div class="hot-table">
    <div v-if="!hideTable">
      <TableElement :element="element" @renderHTML="addHTML" />
    </div>
    <div v-html="tableHTML"></div>
  </div>
</template>

<script>
import TableElement from '../shared/content/table.vue';

export default {
  name: 'NativeTableRenderer',
  components: {
    TableElement
  },
  computed: {
    element() {
      return {
        attributes: {
          orderable: {
            contents: JSON.stringify(this.contents),
            metadata: this.metadata,
            urls: {}
          }
        }
      };
    }
  },
  props: {
    contents: Object,
    metadata: Object
  },
  data() {
    return {
      tableHTML: null,
      hideTable: false
    };
  },
  methods: {
    addHTML(html) {
      this.tableHTML = html;
      this.hideTable = true;
    }
  }
};
</script>
