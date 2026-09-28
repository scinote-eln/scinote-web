<template>
  <div ref="modal" @keydown.esc="close" class="modal sci-reorderable-items" tabindex="-1" role="dialog" :data-e2e="`e2e-MD-${dataE2e}`">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button @click="close" type="button" class="close" data-dismiss="modal" aria-label="Close" :data-e2e="`e2e-BT-${dataE2e}-close`">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 v-if="subject.type == 'steps'" class="modal-title" :data-e2e="`e2e-TX-${dataE2e}-title`">
            {{ i18n.t('protocols.manage_items_modal.title_step', {position: subject.attributes.position + 1}) }}
          </h4>
          <h4 v-else-if="subject.type == 'result_templates'" class="modal-title" :data-e2e="`e2e-TX-${dataE2e}-title`">
            {{ i18n.t('protocols.manage_items_modal.title_result') }}
          </h4>
        </div>
        <div class="modal-body">
          <Draggable
            v-model="orderedItems"
            :ghostClass="'step-checklist-item-ghost'"
            :dragClass="'step-checklist-item-drag'"
            :chosenClass="'step-checklist-item-chosen'"
            :handle="'.step-element-grip'"
            item-key="id"
          >
            <template #item="{element, index}">
              <div class="step-element-header flex items-center">
                <div
                  :class="['step-element-grip step-element-grip--draggable', `e2e-BT-${dataE2e}-element-drag`]"
                  :data-e2e="`e2e-BT-${dataE2e}-element${index + 1}-drag`"
                >
                  <i class="sn-icon sn-icon-drag"></i>
                </div>
                <div class="step-element-name text-center flex items-center gap-2 w-full">
                  <i v-if="element.attributes.icon" class="sn-icon" :class="element.attributes.icon"></i>
                  <span
                    :title="element.attributes.name"
                    class="truncate"
                    :data-e2e="`e2e-TX-${dataE2e}-element${index + 1}-name`"
                  >
                    {{ element.attributes.name }}
                  </span>
                  <a
                    v-if="!subject.attributes.locked"
                    :class="['btn icon-btn ml-auto', `e2e-BT-${dataE2e}-element-lock`]"
                    @click="toggleLock(element)"
                    tabindex="0"
                    :data-e2e="`e2e-BT-${dataE2e}-element${index + 1}-lock`"
                  >
                    <i class="sn-icon" :class="{ 'sn-icon-unlocked': !element.attributes.locked, 'sn-icon-locked-fill': element.attributes.locked }" aria-hidden="true"></i>
                  </a>
                </div>
              </div>
            </template>
          </Draggable>
          <div class="flex items-center border-0 border-solid border-b border-sn-light-grey">
            <span class="flex items-center" :data-e2e="`e2e-BT-${dataE2e}-attachments-name`">
              <div class="step-element-grip step-element-grip--draggable opacity-0">
                <i class="sn-icon sn-icon-drag"></i>
              </div>
              <i class="sn-icon sn-icon-file mr-2"></i>
              {{ i18n.t('protocols.manage_items_modal.attachments') }}
            </span>
            <a
              v-if="!subject.attributes.locked"
              class="btn icon-btn ml-auto"
              :data-sn-tooltip="i18n.t('protocols.manage_items_modal.lock_all')"
              @click="toggleLockAttachments"
              tabindex="0"
              :data-e2e="`e2e-BT-${dataE2e}-attachments-lock`"
            >
              <i class="sn-icon" :class="{
                'sn-icon-unlocked': !subject.attributes.attachments_locked,
                'sn-icon-locked-fill': subject.attributes.attachments_locked
              }" aria-hidden="true"></i>
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import Draggable from 'vuedraggable';

export default {
  name: 'ManageItemsModal',
  components: {
    Draggable
  },
  props: {
    items: {
      type: Array,
      required: true
    },
    subject: {
      type: Object,
      required: true
    },
    dataE2e: {
      type: String,
      default: ''
    }
  },
  watch: {
    items(newItems) {
      this.orderedItems = [...newItems];
    }
  },
  data() {
    return {
      orderedItems: [...this.items]
    };
  },
  mounted() {
    window.$(this.$refs.modal).modal('show');
    window.$(this.$refs.modal).on('hidden.bs.modal', () => {
      this.close();
    });
  },
  methods: {
    close() {
      this.$emit('reorder', this.orderedItems);
      this.$emit('close');
    },
    toggleLock(item) {
      this.$emit('toggle-lock', item);
    },
    toggleLockAttachments() {
      this.$emit('toggle-lock-attachments');
    }
  }
};
</script>
