<template>
  <ManageModal v-if="visibility"
    :repositoryId="repositoryId"
    :repositoryRowId="repositoryRowId"
  ></ManageModal>
</template>

<script>

import ManageModal from '../equipment_bookings/manage_modal.vue';

export default {
  name: 'EventCreateRepositoryRow',
  props: {
    visibility: Boolean,
    repositoryId: {
      type: Number,
      required: true
    },
    repositoryRowId: {
      type: Number,
      required: false
    }
  },
  data() {
    return {};
  },
  components: {
    ManageModal
  }
};
</script>
