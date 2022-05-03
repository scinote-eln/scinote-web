<template>
  <div class="protocol-modals">
    <deleteComponentModal/>
  </div>
</template>
<script>
  import deleteComponentModal from 'vue/protocol/modals/delete_component.vue'

  export default {
    name: 'ProtocolModals',
    components: { deleteComponentModal }
  }
</script>
