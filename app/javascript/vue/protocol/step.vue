<template>
  <div class="step-container">
    <div class="step-header">
      <a class="step-collapse-link"
           :href="'#stepBody' + step.id"
           data-toggle="collapse"
           data-remote="true">
          <span class="fas fa-caret-right"></span>
      </a>
      <div class="step-complete-container">
        <div :class="`step-state ${step.attributes.completed ? 'completed' : ''}`" @click="changeState"></div>
      </div>
      <div class="step-position">
        {{ step.attributes.position + 1 }}.
      </div>
      <div class="step-name-container">
        <InlineEdit
          :value="step.attributes.name"
          :characterLimit="255"
          :allowBlank="false"
          :attributeName="`${i18n.t('Step')} ${i18n.t('name')}`"
          @update="updateName"
        />
      </div>
      <div class="step-actions-container">
        <button class="btn icon-btn btn-light" @click="deleteStep">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <div class="collapse in" :id="'stepBody' + step.id">
      Components here
    </div>
  </div>
</template>

 <script>
  import InlineEdit from 'vue/shared/inline_edit.vue'

  export default {
    name: 'StepContainer',
    props: {
      step: {
        type: Object,
        required: true
      }
    },
    components: { InlineEdit },
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
      },
      changeState() {
        $.post(this.step.attributes.urls.state_url, {completed: !this.step.attributes.completed}, (result) => {
          this.$emit('step:update', result.data)
        })
      },
      updateName(newName) {
        $.ajax({
          url: this.step.attributes.urls.update_url,
          type: 'PATCH',
          data: {step: {name: newName}},
          success: (result) => {
            this.$emit('step:update', result.data)
          }
        });
      }
    }
  }
</script>
