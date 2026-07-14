<template>
  <div ref="modal" @keydown.esc="close" class="modal sci-reorderable-items" tabindex="-1" role="dialog" :data-e2e="`e2e-MD-manageSteps`">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button @click="close" type="button" class="close" data-dismiss="modal" aria-label="Close" :data-e2e="`e2e-BT-manageSteps-close`">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title" :data-e2e="`e2e-TX-manageSteps-title`">
            {{ i18n.t('protocols.manage_steps') }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="flex items-center border-0 border-solid border-b border-sn-light-grey">
            {{ i18n.t('protocols.all_steps') }}

            <a
              class="btn icon-btn ml-auto"
              data-e2e="e2e-BT-protocol-templateSteps-lockStep"
              :data-sn-tooltip="i18n.t('protocols.manage_steps')"
              @click="toggleLockAll(!this.allStepsLocked)"
              tabindex="0" >
              <i class="sn-icon" :class="{ 'sn-icon-unlocked': !allStepsLocked, 'sn-icon-locked-fill': allStepsLocked }" aria-hidden="true"></i>
            </a>
          </div>
          <Draggable
            v-model="orderedSteps"
            :ghostClass="'step-checklist-item-ghost'"
            :dragClass="'step-checklist-item-drag'"
            :chosenClass="'step-checklist-item-chosen'"
            :handle="'.step-element-grip'"
            item-key="id"
          >
            <template #item="{element, index}">
              <div class="step-element-header flex items-center">
                <div class="step-element-grip step-element-grip--draggable">
                  <i class="sn-icon sn-icon-drag" :data-e2e="`e2e-BT-manageSteps-element${index + 1}-drag`"></i>
                </div>
                <div class="step-element-name text-center flex items-center gap-2 w-full">
                  <strong class="step-element-number" :data-e2e="`e2e-TX-manageSteps-element${index + 1}-position`">
                    {{ index + 1 }}
                  </strong>
                  <i v-if="element.attributes.icon" class="sn-icon" :class="element.attributes.icon" :data-e2e="`e2e-IC-manageSteps-element${index + 1}`"></i>
                  <span
                    :title="element.attributes.name"
                    :data-e2e="`e2e-TX-manageSteps-element${index + 1}-name`"
                    class="truncate"
                  >
                    {{ element.attributes.name }}
                  </span>
                  <a
                    class="btn icon-btn ml-auto"
                    data-e2e="e2e-BT-protocol-templateSteps-lockStep"
                    :data-sn-tooltip="i18n.t('protocols.manage_steps')"
                    @click="toggleLock(element)"
                    tabindex="0" >
                    <i class="sn-icon" :class="{ 'sn-icon-unlocked': !element.attributes.locked, 'sn-icon-locked-fill': element.attributes.locked }" aria-hidden="true"></i>
                  </a>
                </div>
              </div>
            </template>
          </Draggable>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import Draggable from 'vuedraggable';

export default {
  name: 'ManageStepsModal',
  components: {
    Draggable
  },
  props: {
    steps: {
      type: Array,
      required: true
    },
    protocol: {
      type: Object,
      required: true
    }
  },
  watch: {
    steps(newSteps) {
      this.orderedSteps = [...newSteps];
    }
  },
  data() {
    return {
      orderedSteps: [...this.steps]
    };
  },
  computed: {
    allStepsLocked() {
      return this.orderedSteps.every((step) => step.attributes.locked);
    }
  },
  mounted() {
    window.$(this.$refs.modal).modal('show');
    window.$(this.$refs.modal).on('hidden.bs.modal', () => {
      this.close();
    });
  },
  methods: {
    close() {
      this.$emit('reorder', this.orderedSteps);
      this.$emit('close');
    },
    toggleLock(step) {
      this.$emit('toggle-lock', step);
    },
    toggleLockAll(locked) {
      this.$emit('toggle-lock-all', locked);
    }
  }
};
</script>
