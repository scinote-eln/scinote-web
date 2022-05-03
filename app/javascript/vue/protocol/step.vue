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
        <div class="dropdown">
          <button class="btn btn-light dropdown-toggle insert-button" type="button" :id="'stepInserMenu_' + step.id" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
            {{ i18n.t('protocols.steps.insert.button') }}
            <span class="caret"></span>
          </button>
          <ul class="dropdown-menu insert-element-dropdown" :aria-labelledby="'stepInserMenu_' + step.id">
            <li class="title">
              {{ i18n.t('protocols.steps.insert.title') }}
            </li>
            <li class="action" @click="createElement('table')">
              <i class="fas fa-table"></i>
              {{ i18n.t('protocols.steps.insert.table') }}
            </li>
            <li class="action" @click="createElement('checklist')">
              <i class="fas fa-list"></i>
              {{ i18n.t('protocols.steps.insert.checklist') }}
            </li>
            <li class="action"  @click="createElement('text')">
              <i class="fas fa-font"></i>
              {{ i18n.t('protocols.steps.insert.text') }}
            </li>
          </ul>
        </div>
        <button class="btn icon-btn btn-light" @click="deleteStep">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <div class="collapse in" :id="'stepBody' + step.id">
      <template v-for="(element, index) in elements">
        <component
          :is="elements[index].attributes.orderable_type"
          :key="index"
          @component:delete="deleteComponent"
          :element.sync="elements[index]"/>
      </template>
    </div>
  </div>
</template>

 <script>
  import InlineEdit from 'vue/shared/inline_edit.vue'
  import StepTable from 'vue/protocol/step_components/table.vue'
  import StepText from 'vue/protocol/step_components/text.vue'
  import Checklist from 'vue/protocol/step_components/checklist.vue'

  export default {
    name: 'StepContainer',
    props: {
      step: {
        type: Object,
        required: true
      }
    },
    data() {
      return {
        elements: []
      }
    },
    components: {
      InlineEdit,
      StepTable,
      StepText,
      Checklist
    },
    created() {
      $.get(this.step.attributes.urls.elements_url, (result) => {
        this.elements = result.data
      });
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
      },
      changeState() {
        this.step.attributes.completed = !this.step.attributes.completed;
        this.$emit('step:update', this.step)
        $.post(this.step.attributes.urls.state_url, {completed: this.step.attributes.completed}).error(() => {
          this.step.attributes.completed = !this.step.attributes.completed;
          this.$emit('step:update', this.step)
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        })
      },
      deleteComponent(element) {
        let position = element.attributes.position;
        this.elements.splice(position, 1)
        let unordered_elements = this.elements.map( e => {
          if (e.attributes.position >= position) {
            e.attributes.position -= 1;
          }
          return e;
        })
        this.reorderComponents(unordered_elements)

      },
      reorderComponents(elements) {
        this.elements = elements.sort((a, b) => a.attributes.position - b.attributes.position);
      },
      updateName(newName) {
        $.ajax({
          url: this.step.attributes.urls.update_url,
          type: 'PATCH',
          data: {step: {name: newName}},
          success: (result) => {
            this.$emit('step:update', result.data.attributes)
          }
        });
      },
      createElement(elementType) {
        $.post(this.step.attributes.urls[`create_${elementType}_url`], (result) => {
          this.elements.push(result.data)
        }).error(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        })
      }
    }
  }
</script>
