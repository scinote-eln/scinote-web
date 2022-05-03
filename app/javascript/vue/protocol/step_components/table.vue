<template>
  <div class="step-table-container">
    Table
    <button class="btn icon-btn btn-light" @click="showDeleteModal">
      <i class="fas fa-trash"></i>
    </button>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  export default {
    name: 'StepTable',
    mixins: [DeleteMixin],
    props: {
      element: {
        type: Object,
        required: true
      }
    }
  }
</script>
