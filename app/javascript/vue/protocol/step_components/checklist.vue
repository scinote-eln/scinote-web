<template>
  <div class="step-checklist-container">
    Checklist
   <button class="btn icon-btn btn-light" @click="showDeleteModal">
      <i class="fas fa-trash"></i>
    </button>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  export default {
    name: 'Checklist',
    mixins: [DeleteMixin],
    props: {
      element: {
        type: Object,
        required: true
      }
    }
  }
</script>
