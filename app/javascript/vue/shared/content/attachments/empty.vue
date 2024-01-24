<template>
  <div class="attachment-container asset" :data-asset-id="attachment.id">
    <div
      class="file-name"
      :id="`modal_link${attachment.id}`"
      data-no-turbolink="true"
      :data-id="attachment.id"
    >
      <div class="attachment-preview processing" :class= "attachment.attributes.asset_type"></div>
    </div>
  </div>

</template>

<script>
export default {
  name: 'emptyAttachment',
  props: {
    attachment: {
      type: Object,
      required: true
    },
    parentId: {
      type: Number,
      required: true
    }
  }
};
</script>
