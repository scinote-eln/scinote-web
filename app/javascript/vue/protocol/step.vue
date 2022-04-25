<template>
  <div class="step-container">
    {{ step.attributes.position + 1 }}
    {{ step.attributes.name }}
    <button class="btn btn-danger" @click="deleteStep">
      <i class="fas fa-trash"></i>
      {{ i18n.t("protocols.steps.options.delete_title") }}
    </button>
  </div>
</template>

 <script>
  export default {
    name: 'StepContainer',
    props: {
      step: {
        type: Object,
        required: true
      }
    },
    methods: {
      deleteStep() {
        $.ajax({
          url: this.step.attributes.urls.delete_url,
          type: 'DELETE',
          success: (result) => {
            this.$emit(
              'step:delete',
              result.data,
              'delete'
            );
          }
        });
      }
    }
  }
</script>
