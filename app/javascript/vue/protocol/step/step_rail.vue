<template>
  <div class="flex flex-col items-center shrink-0">
    <span v-if="showDuplicate" :data-sn-tooltip="addingStepsLocked ? i18n.t('protocols.action_disabled') : i18n.t('protocols.steps.options_dropdown.duplicate')">
      <button type="button"
              :class="[btnClasses, 'e2e-BT-protocol-step-stepOptions-duplicate']"
              :disabled="addingStepsLocked"
              :data-e2e="`e2e-BT-protocol-step${step.id}-stepOptions-duplicate`"
              @click="$emit('duplicate')">
        <i class="sn-icon sn-icon-duplicate"></i>
      </button>
    </span>

    <!-- Task steps archive, template drafts delete; a step never offers both -->
    <span v-if="urls.archive_url && canChangeStep"
          :data-sn-tooltip="addingStepsLocked ? i18n.t('protocols.action_disabled') : i18n.t('protocols.steps.options_dropdown.archive')">
      <button type="button"
              :class="[btnClasses, 'e2e-BT-protocol-step-stepOptions-archive']"
              :disabled="addingStepsLocked"
              :data-e2e="`e2e-BT-protocol-step${step.id}-stepOptions-archive`"
              @click="$emit('archive')">
        <i class="sn-icon sn-icon-archive"></i>
      </button>
    </span>
    <button v-else-if="urls.delete_url && canChangeStep"
            type="button"
            :class="[btnClasses, 'e2e-BT-protocol-step-stepOptions-delete']"
            :data-sn-tooltip="i18n.t('protocols.steps.options_dropdown.delete')"
            :data-e2e="`e2e-BT-protocol-step${step.id}-stepOptions-delete`"
            @click="$emit('delete')">
      <i class="sn-icon sn-icon-delete"></i>
    </button>

    <template v-if="!empty && !step.attributes.locked">
      <button v-if="urls.lock_url"
              type="button"
              :class="[btnClasses, 'e2e-BT-protocol-step-stepOptions-manage']"
              :data-sn-tooltip="i18n.t('protocols.steps.manage_content')"
              :data-e2e="`e2e-BT-protocol-step${step.id}-stepOptions-manage`"
              @click="$emit('reorder')">
        <i class="sn-icon sn-icon-sort" aria-hidden="true"></i>
      </button>
      <button v-else-if="urls.reorder_elements_url && elementsCount > 1"
              type="button"
              :class="[btnClasses, 'e2e-BT-protocol-step-stepOptions-reorder']"
              :data-sn-tooltip="i18n.t('protocols.steps.rearrange_content')"
              :data-e2e="`e2e-BT-protocol-step${step.id}-stepOptions-reorder`"
              @click="$emit('reorder')">
        <i class="sn-icon sn-icon-sort" aria-hidden="true"></i>
      </button>
    </template>

    <template v-if="results.length === 0">
      <button v-if="permissions.can_link_results"
              type="button"
              :class="btnClasses"
              :data-sn-tooltip="i18n.t('protocols.steps.link_results')"
              :data-e2e="`e2e-BT-protocol-step${step.id}-linkResults`"
              @click="$emit('link-results')">
        <i class="sn-icon sn-icon-results"></i>
      </button>
    </template>
    <GeneralDropdown v-else ref="linkedResultsDropdown" position="right">
      <template v-slot:field>
        <button type="button"
                :class="btnClasses"
                :data-sn-tooltip="i18n.t('protocols.steps.linked_results')"
                :data-e2e="`e2e-BT-protocol-step${step.id}-linkedResults`">
          <i class="sn-icon sn-icon-results"></i>
          <span class="absolute top-1 right-1 h-4 min-w-4 bg-sn-science-blue text-white flex items-center justify-center rounded-full text-[10px]">
            {{ results.length }}
          </span>
        </button>
      </template>
      <template v-slot:flyout>
        <div class="overflow-y-auto max-h-[calc(50vh_-_6rem)]">
          <a v-for="result in results"
             :key="result.id"
             :data-sn-tooltip="result.name"
             :href="resultUrl(result.id, result.archived)"
             class="py-2.5 px-3 hover:bg-sn-super-light-grey cursor-pointer hover:no-underline text-sn-blue truncate flex items-center gap-2">
            <i v-if="result.archived" class="sn-icon sn-icon-archived"></i>
            {{ result.name }}
          </a>
        </div>
        <template v-if="permissions.can_link_results">
          <hr class="my-0">
          <div class="py-2.5 px-3 hover:bg-sn-super-light-grey cursor-pointer text-sn-blue"
               :data-e2e="`e2e-BT-protocol-step${step.id}-manageLinks`"
               @click="$emit('link-results'); $refs.linkedResultsDropdown.closeMenu()">
            {{ i18n.t('protocols.steps.manage_links') }}
          </div>
        </template>
      </template>
    </GeneralDropdown>

    <!-- .open-comments-sidebar is picked up by the legacy sitewide comments sidebar -->
    <a v-if="!inRepository"
       href=" #"
       :class="[btnClasses, 'open-comments-sidebar']"
       data-turbolinks="false"
       data-object-type="Step"
       :data-object-id="step.id"
       :data-sn-tooltip="i18n.t('protocols.steps.comments')"
       :data-e2e="`e2e-BT-protocol-step${step.id}-comments`"
       @click="closeOpenSidebar">
      <i class="sn-icon sn-icon-comments"></i>
      <span class="comments-counter"
            :id="`comment-count-${step.id}`"
            :class="{ 'unseen': step.attributes.unseen_comments, 'hidden': !step.attributes.comments_count }">
        {{ step.attributes.comments_count }}
      </span>
    </a>
  </div>
</template>

<script>
import GeneralDropdown from '../../shared/general_dropdown.vue';

export default {
  name: 'StepRail',
  components: { GeneralDropdown },
  props: {
    step: { type: Object, required: true },
    inRepository: { type: Boolean, required: true },
    addingStepsLocked: { type: Boolean, default: false },
    // Empty steps get the short rail: archive/delete, linked results, comments
    empty: { type: Boolean, default: false },
    elementsCount: { type: Number, default: 0 },
    resultUrl: { type: Function, required: true }
  },
  emits: ['duplicate', 'archive', 'delete', 'reorder', 'link-results'],
  computed: {
    urls() {
      return this.step.attributes.urls || {};
    },
    permissions() {
      return this.step.attributes.permissions || {};
    },
    results() {
      return this.step.attributes.results || [];
    },
    // A locked step on a task can't be duplicated, archived or deleted (templates manage locks themselves)
    canChangeStep() {
      return this.inRepository || !this.step.attributes.locked;
    },
    showDuplicate() {
      return !this.empty && this.canChangeStep && !!this.urls.duplicate_step_url;
    },
    // Large tertiary-black icon buttons on the grey body: transparent, light-grey hover
    btnClasses() {
      return 'btn btn-light btn-black btn-lg icon-btn w-11 !bg-transparent hover:!bg-sn-light-grey disabled:hover:!bg-transparent';
    }
  },
  methods: {
    closeOpenSidebar() {
      $('.comments-sidebar .close-btn').click();
    }
  }
};
</script>
