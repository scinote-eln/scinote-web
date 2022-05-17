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
        <button class="btn icon-btn btn-light" @click="showDeleteModal">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <div class="collapse in" :id="'stepBody' + step.id">
      <template v-for="(element, index) in elements">
        <component
          :is="elements[index].attributes.orderable_type"
          :key="index"
          :element.sync="elements[index]"
          @component:delete="deleteComponent"
          @update="updateComponent" />
      </template>
    </div>
    <div v-if="attachments.length" class="step-attachments">
      <div class="attachments-actions">
        <div class="title">
          <h4>{{ i18n.t('protocols.steps.files', {count: attachments.length}) }}</h4>
        </div>
        <div class="actions">
          <div class="dropdown sci-dropdown">
            <button class="btn btn-light dropdown-toggle" type="button" id="dropdownAttachmentsOptions" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
              <span>{{ i18n.t("protocols.steps.attachments.manage") }}</span>
              <span class="caret pull-right"></span>
            </button>
            <ul class="dropdown-menu dropdown-menu-right dropdown-attachment-options"
                aria-labelledby="dropdownAttachmentsOptions"
                :data-step-id="step.id"
            >
              <li class="divider-label">{{ i18n.t("protocols.steps.attachments.add") }}</li>
              <li role="separator" class="divider"></li>
              <li class="divider-label">{{ i18n.t("protocols.steps.attachments.sort_by") }}</li>
              <li v-for="(orderOption, index) in orderOptions" :key="`orderOption_${index}`">
                <a class="action-link change-order"
                   @click="changeAttachmentsOrder(orderOption)"
                   :class="step.attributes.assets_order == orderOption ? 'selected' : ''"
                >
                  {{ i18n.t(`general.sort_new.${orderOption}`) }}
                </a>
              </li>
              <li role="separator" class="divider"></li>
              <li class="divider-label">{{ i18n.t("protocols.steps.attachments.attachments_view_mode") }}</li>
              <li v-for="(viewMode, index) in viewModeOptions" :key="`viewMode_${index}`">
                <a
                  class="attachments-view-mode action-link"
                  :class="viewMode == step.attributes.assets_view_mode ? 'selected' : ''"
                  @click="changeAttachmentsViewMode(viewMode)"
                  v-html="i18n.t(`protocols.steps.attachments.view_mode.${viewMode}_html`)"
                ></a>
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div class="attachments">
        <template v-for="(attachment, index) in attachmentsOrdered">
          <component
            :is="`${attachmentsOrdered[index].attributes.view_mode}Attachment`"
            :key="index"
            :attachment.sync="attachmentsOrdered[index]"
            :stepId="parseInt(step.id)"
            @attachment:viewMode="updateAttachmentViewMode"
            @attachment:delete="attachments.splice(index, 1)"
          />
        </template>
      </div>
    </div>
    <deleteStepModal v-if="confirmingDelete" @confirm="deleteStep" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import InlineEdit from 'vue/shared/inline_edit.vue'
  import StepTable from 'vue/protocol/step_components/table.vue'
  import StepText from 'vue/protocol/step_components/text.vue'
  import Checklist from 'vue/protocol/step_components/checklist.vue'
  import deleteStepModal from 'vue/protocol/modals/delete_step.vue'
  import listAttachment from 'vue/protocol/step_attachments/list.vue'
  import inlineAttachment from 'vue/protocol/step_attachments/inline.vue'
  import thumbnailAttachment from 'vue/protocol/step_attachments/thumbnail.vue'

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
        elements: [],
        attachments: [],
        viewModeOptions: ['inline', 'thumbnail', 'list'],
        orderOptions: ['new', 'old', 'atoz', 'ztoa'],
        confirmingDelete: false
      }
    },
    components: {
      InlineEdit,
      StepTable,
      StepText,
      Checklist,
      deleteStepModal,
      thumbnailAttachment,
      inlineAttachment,
      listAttachment
    },
    created() {
      $.get(this.step.attributes.urls.elements_url, (result) => {
        this.elements = result.data
      });

      $.get(this.step.attributes.urls.attachments_url, (result) => {
        this.attachments = result.data
      });
    },
    computed: {
      attachmentsOrdered() {
        return this.attachments.sort((a, b) => {
          if (a.attributes.asset_order == b.attributes.asset_order) {
            switch(this.step.attributes.assets_order) {
              case 'new':
                return b.attributes.updated_at - a.attributes.updated_at;
              case 'old':
                return a.attributes.updated_at - b.attributes.updated_at;
              case 'atoz':
                return a.attributes.file_name.toLowerCase() > b.attributes.file_name.toLowerCase() ? 1 : -1;
              case 'ztoa':
                return b.attributes.file_name.toLowerCase() > a.attributes.file_name.toLowerCase() ? 1 : -1;
            }
          }

          return a.attributes.asset_order > b.attributes.asset_order ? 1 : -1;
        })
      }
    },
    methods: {
      showDeleteModal() {
        this.confirmingDelete = true;
      },
      closeDeleteModal() {
        this.confirmingDelete = false;
      },
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
        this.$emit('step:update', this.step.attributes)
        $.post(this.step.attributes.urls.state_url, {completed: this.step.attributes.completed}).error(() => {
          this.step.attributes.completed = !this.step.attributes.completed;
          this.$emit('step:update', this.step.attributes)
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
      updateComponent(element, skipRequest=false) {
        let index = this.elements.findIndex((e) => e.id === element.id);

        if (skipRequest) {
          this.elements[index].orderable = element;
        } else {
          $.ajax({
            url: element.attributes.orderable.urls.update_url,
            method: 'PUT',
            data: element.attributes.orderable,
            success: (result) => {
              this.elements[index].orderable = result;
            }
          }).error(() => {
            HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
          })
        }
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
      },
      changeAttachmentsOrder(order) {
        this.step.attributes.assets_order = order;
        $.post(this.step.attributes.urls.update_view_state_step_url, {
          assets: { order: order }
        });
      },
      changeAttachmentsViewMode(viewMode) {
        this.step.attributes.assets_view_mode = viewMode
        this.attachments.forEach((attachment) => {
          this.$set(attachment.attributes, 'view_mode', viewMode);
        });
        $.post(this.step.attributes.urls.update_asset_view_mode_url, {
          assets_view_mode: viewMode
        })
      },
      updateAttachmentViewMode(id, viewMode) {
        this.$set(this.attachments.find(e => e.id == id).attributes, 'view_mode', viewMode)
      }
    }
  }
</script>
