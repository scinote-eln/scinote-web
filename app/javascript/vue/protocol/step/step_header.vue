<template>
  <div class="flex items-start gap-4">
    <div class="flex items-start gap-1 grow min-w-0">
      <!-- 8px to the text (Figma says 4; widened on Bor's review) -->
      <div v-if="!inRepository" class="flex flex-col gap-1 shrink-0 mr-1">
        <div class="flex items-center justify-center cursor-pointer"
             :class="[
               step.attributes.completed ? 'text-sn-alert-green' : 'text-sn-grey-700 hover:text-sn-alert-green-disabled',
               { 'step-element--locked': !urls.state_url }
             ]"
             tabindex="0"
             :data-sn-tooltip="completeStateTooltip"
             :data-e2e="`e2e-BT-protocol-step${step.id}-toggleCompleted`"
             @click="$emit('toggle-complete')"
             @keyup.enter="$emit('toggle-complete')">
          <i :class="['sn-icon', step.attributes.completed ? 'sn-icon-task-status-completed' : 'sn-icon-task-status-uncompleted']"></i>
        </div>
        <div class="flex items-center justify-center cursor-pointer"
             :class="[
               step.attributes.skipped_at ? 'text-sn-science-blue hover:text-sn-blue-click' : 'text-sn-grey-700 hover:text-sn-science-blue',
               { 'step-element--locked': !urls.skip_url }
             ]"
             tabindex="0"
             :data-sn-tooltip="skipStateTooltip"
             data-e2e="e2e-BT-protocol-toggleSkipped"
             @click="$emit('toggle-skip')"
             @keyup.enter="$emit('toggle-skip')">
          <i :class="['sn-icon', step.attributes.skipped_at ? 'sn-icon-skip-fill' : 'sn-icon-skip-outline']"
             :data-e2e="`e2e-BT-protocol-step${step.id}-toggleSkipped`"></i>
        </div>
      </div>
      <div class="shrink-0 text-base leading-6 font-semibold" :data-e2e="`e2e-TX-protocol-step${step.id}-position`">
        {{ step.attributes.position + 1 }}.
      </div>
      <div class="flex flex-col gap-2 grow min-w-0">
        <div class="text-base font-semibold"
             :class="{ 'step-element--locked': !urls.update_url, 'opacity-30': step.attributes.skipped_at }">
          <InlineEdit
            :value="step.attributes.name"
            :class="{ 'step-element--locked': !urls.update_url }"
            :characterLimit="255"
            :allowBlank="false"
            :attributeName="`${i18n.t('Step')} ${i18n.t('name')}`"
            :autofocus="editingName"
            :singleLine="false"
            :flush="true"
            :placeholder="i18n.t('protocols.steps.placeholder')"
            :defaultValue="i18n.t('protocols.steps.default_name')"
            :editOnload="step.newStep == true"
            :dataE2e="`protocol-step${step.id}-title`"
            @editingEnabled="$emit('editing', true)"
            @editingDisabled="$emit('editing', false)"
            @update="$emit('update-name', $event)"
          />
        </div>
        <!-- Hidden (not removed) while editing, so InlineEdit's validation message has room -->
        <div class="flex flex-wrap gap-1 text-xs leading-[18px] font-normal text-sn-black"
             :class="{ invisible: editingName }"
             :data-e2e="`e2e-TX-protocol-step${step.id}-timestamps`">
          <span>{{ i18n.t('protocols.steps.timestamp', { date: step.attributes.created_at, user: step.attributes.created_by }) }}</span>
          <template v-if="step.attributes.status_timestamp">
            <span aria-hidden="true">|</span>
            <span>{{ step.attributes.status_timestamp }}</span>
          </template>
        </div>
      </div>
    </div>
    <div class="flex items-center gap-2 shrink-0">
      <LockedTag v-if="step.attributes.locked" />
      <button type="button"
              class="btn btn-light btn-black btn-lg icon-btn w-11"
              :aria-expanded="!isCollapsed"
              :aria-controls="`stepBody${step.id}`"
              :data-sn-tooltip="isCollapsed ? i18n.t('protocols.steps.expand_step') : i18n.t('protocols.steps.collapse_step')"
              :data-e2e="`e2e-BT-protocol-step${step.id}-toggleCollapsed`"
              @click="$emit('toggle-collapse')">
        <i :class="['sn-icon', isCollapsed ? 'sn-icon-right' : 'sn-icon-down']"></i>
      </button>
    </div>
  </div>
</template>

<script>
import InlineEdit from '../../shared/inline_edit.vue';
import LockedTag from '../../shared/snippets/locked_tag.vue';

export default {
  name: 'StepHeader',
  components: { InlineEdit, LockedTag },
  props: {
    step: { type: Object, required: true },
    inRepository: { type: Boolean, required: true },
    isCollapsed: { type: Boolean, default: false },
    editingName: { type: Boolean, default: false }
  },
  emits: ['toggle-complete', 'toggle-skip', 'toggle-collapse', 'update-name', 'editing'],
  computed: {
    urls() {
      return this.step.attributes.urls || {};
    },
    completeStateTooltip() {
      return this.step.attributes.completed
        ? this.i18n.t('protocols.steps.status.uncomplete')
        : this.i18n.t('protocols.steps.status.complete');
    },
    skipStateTooltip() {
      return this.step.attributes.skipped_at
        ? this.i18n.t('protocols.steps.status.unskip')
        : this.i18n.t('protocols.steps.status.skip');
    }
  }
};
</script>
