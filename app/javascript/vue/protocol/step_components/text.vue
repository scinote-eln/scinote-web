<template>
  <div class="step-text-container">
    Text
   <button class="btn icon-btn btn-light" @click="showDeleteModal">
      <i class="fas fa-trash"></i>
    </button>
    <deleteComponentModal v-if="confirmingDelete" @confirm="deleteComponent" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import deleteComponentModal from 'vue/protocol/modals/delete_component.vue'

  export default {
    name: 'StepText',
    components: { deleteComponentModal },
    mixins: [DeleteMixin],
    props: {
      element: {
        type: Object,
        required: true
      }
    }
  }
</script>
