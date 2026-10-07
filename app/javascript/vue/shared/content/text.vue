<template>
  <div class="content__text-container pr-8"
    :data-e2e="`e2e-CO-${dataE2e}-textElement${element.id}`">
    <div :class="{'!bg-sn-background-brittlebush p-4': element.archived}">
    <div class="sci-divider my-6" v-if="!inRepository"></div>
      <div class="text-header h-9 flex rounded mb-1 gap-2 items-center relative w-full group/text-header"
        :class="{ 'editing-name': editingName,
        'locked': !element.urls.update_url }">
        <div v-if="element.urls.update_url || element.name"
            class="text-ellipsis whitespace-nowrap my-1 font-bold"
            :class="{'grow': !this.element.archived,
                     'pointer-events-none': locked}">
          <InlineEdit
            ref="nameInlineEdit"
            :value="element.name"
            :characterLimit="255"
            :placeholder="i18n.t('protocols.steps.text.text_name')"
            :allowBlank="true"
            :autofocus="editingName"
            :attributeName="`${i18n.t('Text')} ${i18n.t('name')}`"
            :dataE2e="`${dataE2e}-textElement${element.id}-title`"
            @editingEnabled="enableNameEdit"
            @editingDisabled="disableNameEdit"
            @update="updateName"
          >
            <template v-if="editingFlags.length" #suffix>
              <div class="flex items-center shrink-0 ml-2">
                <EditingTag
                  v-for="(flag, index) in editingFlags"
                  :key="flag.id"
                  :user="flag.attributes.user"
                  :class="{ '-mr-1': index !== editingFlags.length - 1 }"
                />
              </div>
            </template>
          </InlineEdit>
        </div>
        <template v-if="this.element.archived">
          <div class="sci-tag bg-sn-alert-brittlebush pointer-events-none text-sn-black">
            {{ i18n.t('my_modules.results.archived') }}
            <span class="sn-icon sn-icon-archived"></span>
          </div>
          <span class="text-xs ">
            {{ i18n.t('protocols.steps.timestamp_archived', {
              date: this.element.archived_on,
              user: this.element.archived_by
            }) }}
          </span>
        </template>
        <div class="ml-auto flex items gap-4">
          <LockedTag v-if="element.locked" />
          <button
            v-if="this.element.urls.restore_url"
            :class="['btn icon-btn btn-light', `e2e-BT-${this.e2eClass}-textElement-options-restore`]"
            @click="confirmingRestore = true"
            :title="i18n.t('general.restore')"
            :data-e2e="`e2e-BT-${this.dataE2e}-textElement${this.element.id}-options-restore`"
          >
            <i class="sn-icon sn-icon-restore"></i>
          </button>
          <button
            v-if="this.element.archived && this.element.urls.delete_url"
            :class="['btn icon-btn btn-light', `e2e-BT-${this.e2eClass}-textElement-options-delete`]"
            @click="showDeleteModal"
            :title="i18n.t('general.delete')"
            :data-e2e="`e2e-BT-${this.dataE2e}-textElement${this.element.id}-options-delete`"
          >
            <i class="sn-icon sn-icon-delete"></i>
          </button>
          <MenuDropdown
            v-if="inRepository || !this.element.locked"
            :listItems="this.actionMenu"
            :btnClasses="'btn btn-light icon-btn btn-sm'"
            :position="'right'"
            :btnIcon="'sn-icon sn-icon-more-hori'"
            :dataE2e="`e2e-DD-${dataE2e}-textElement${element.id}-options`"
            @edit="enableNameEdit"
            @duplicate="duplicateElement"
            @move="showMoveModal"
            @delete="showDeleteModal"
            @archive="archiveElement"
            @restore="restoreElement"
          ></MenuDropdown>
        </div>
      </div>
      <div class="flex rounded min-h-[2.25rem] mb-4 relative group/text_container content__text-body"
        :class="{ 'edit': inEditMode, 'component__element--locked': !element.urls.update_url }"
        :data-e2e="`e2e-IF-${dataE2e}-textElement${element.id}-content`"
        @keyup.enter="enableEditMode($event)"
        tabindex="0">
        <Tinymce
          v-if="element.urls.update_url"
          ref="tinymce"
          :value="element.text"
          :value_html="element.text_view"
          :placeholder="element.placeholder"
          :inEditMode="inEditMode || isNew"
          :updateUrl="element.urls.update_url"
          :objectType="'TextContent'"
          :objectId="element.id"
          :fieldName="'text_component[text]'"
          :lastUpdated="element.updated_at"
          :assignableMyModuleId="assignableMyModuleId"
          :characterLimit="1000000"
          :textDigest="element.text_digest"
          :newVersionAvailable="Boolean(latestVersion)"
          :editingFlags="editingFlags"
          @update="updateText"
          @editingDisabled="disableEditMode"
          @editingEnabled="enableEditMode"
          @showLatestVersion="openNewVersionModal"
          @conflict="handleConflict"
          @saveFailed="onSaveFailed"
        />
        <div class="view-text-element" v-else-if="element.text_view" v-html="wrappedTables" :data-e2e="`e2e-TX-${dataE2e}-textElement${element.id}`"></div>
        <div v-else class="text-sn-grey" :data-e2e="`e2e-TX-${dataE2e}-textElement${element.id}-empty`">
          {{ i18n.t("protocols.steps.text.empty_text") }}
        </div>
      </div>
    </div>
    <deleteElementModal v-if="confirmingDelete" :inRepository="inRepository" @confirm="deleteElement($event)" @close="closeDeleteModal"/>
    <RestoreModal v-if="confirmingRestore"
                  :parentType="element.parent_type"
                  :element="'text'"
                  @confirm="restoreElement"
                  @close="confirmingRestore = false"/>
    <moveElementModal v-if="movingElement"
                      :parent_type="element.parent_type"
                      :targets_url="element.urls.move_targets_url"
                      @confirm="moveElement($event)" @cancel="closeMoveModal"/>
    <NewVersionModal v-if="showingNewVersionModal"
                     :latestVersion="latestVersion"
                     @overwrite="onNewVersionOverwrite"
                     @close="onNewVersionModalClose"/>
  </div>
</template>

<script>
import DeleteMixin from './mixins/delete.js';
import MoveMixin from './mixins/move.js';
import DuplicateMixin from './mixins/duplicate.js';
import ArchiveMixin from './mixins/archive.js';
import deleteElementModal from './modal/delete.vue';
import moveElementModal from './modal/move.vue';
import RestoreModal from './modal/restore_element.vue';
import NewVersionModal from './modal/new_version.vue';
import InlineEdit from '../inline_edit.vue';
import Tinymce from '../tinymce.vue';
import MenuDropdown from '../menu_dropdown.vue';
import axios from '../../../packs/custom_axios';
import tooltipMixin from '../../mixins/tooltipMixin.js';
import LockedTag from '../snippets/locked_tag.vue';
import EditingTag from '../snippets/editing_tag.vue';

export default {
  name: 'TextContent',
  components: {
    deleteElementModal, Tinymce, moveElementModal, InlineEdit, MenuDropdown, RestoreModal, LockedTag, EditingTag, NewVersionModal
  },
  mixins: [DeleteMixin, DuplicateMixin, MoveMixin, ArchiveMixin, tooltipMixin],
  props: {
    element: {
      type: Object,
      required: true
    },
    inRepository: {
      type: Boolean,
      required: true
    },
    reorderElementUrl: {
      type: String
    },
    isNew: {
      type: Boolean,
      default: false
    },
    assignableMyModuleId: {
      type: Number,
      required: false
    },
    dataE2e: {
      type: String,
      default: ''
    },
    e2eClass: {
      type: String,
      default: ''
    },
    editingFlags: {
      type: Array,
      default: () => []
    },
    remoteVersion: {
      type: Object,
      default: null
    }
  },
  data() {
    return {
      inEditMode: false,
      editingName: false,
      confirmingRestore: false,
      pendingRemoteReload: false,
      reloadRequestSeq: 0,
      latestVersion: null,
      showingNewVersionModal: false,
      pendingOverwriteDigest: null
    };
  },
  watch: {
    remoteVersion(newVersion) {
      if (!newVersion) return;

      if (this.editorOpen()) {
        this.checkForNewVersion();
        return;
      }

      if (this.nameEditOpen()) {
        this.pendingRemoteReload = true;
        return;
      }

      this.reloadLatest();
    }
  },
  mounted() {
    if (this.isNew) {
      this.enableEditMode();
    }
    this.$nextTick(() => {
      const textElements = document.querySelectorAll('.view-text-element');
      if (textElements.length > 0) {
        textElements.forEach((textElement) => {
          this.highlightText(textElement);
        });
      }
    });
  },
  computed: {
    locked() {
      return !this.element.urls.update_url;
    },
    wrappedTables() {
      return window.wrapTables(this.element.text_view);
    },
    actionMenu() {
      const menu = [];
      if (this.element.urls.update_url) {
        menu.push({
          text: I18n.t('general.edit'),
          emit: 'edit',
          data_e2e: `e2e-BT-${this.dataE2e}-textElement${this.element.id}-options-edit`,
          e2e_class: `e2e-BT-${this.e2eClass}-textElement-options-edit`
        });
      }
      if (this.element.urls.duplicate_url) {
        menu.push({
          text: I18n.t('general.duplicate'),
          emit: 'duplicate',
          data_e2e: `e2e-BT-${this.dataE2e}-textElement${this.element.id}-options-duplicate`,
          e2e_class: `e2e-BT-${this.e2eClass}-textElement-options-duplicate`
        });
      }
      if (this.element.urls.move_targets_url) {
        menu.push({
          text: I18n.t('general.move'),
          emit: 'move',
          data_e2e: `e2e-BT-${this.dataE2e}-textElement${this.element.id}-options-move`,
          e2e_class: `e2e-BT-${this.e2eClass}-textElement-options-move`
        });
      }
      if (this.element.urls.archive_url) {
        menu.push({
          text: I18n.t('general.archive'),
          emit: 'archive',
          data_e2e: `e2e-BT-${this.dataE2e}-textElement${this.element.id}-options-archive`,
          e2e_class: `e2e-BT-${this.e2eClass}-textElement-options-archive`
        });
      }
      if (!this.element.archived && this.element.urls.delete_url) {
        menu.push({
          text: this.i18n.t('general.delete'),
          emit: 'delete',
          data_e2e: `e2e-BT-${this.dataE2e}-textElement${this.element.id}-options-delete`,
          e2e_class: `e2e-BT-${this.e2eClass}-textElement-options-delete`
        });
      }
      return menu;
    }
  },
  methods: {
    enableEditMode() {
      if (!this.element.urls.update_url) return;
      if (this.inEditMode) return;
      this.inEditMode = true;
      this.$emit('component:editing-start', this.element);
    },
    disableEditMode() {
      this.inEditMode = false;
      this.$emit('component:editing-end', this.element);
      this.latestVersion = null;
      this.showingNewVersionModal = false;
      this.pendingOverwriteDigest = null;

      if (this.pendingRemoteReload && !this.nameEditOpen()) {
        this.pendingRemoteReload = false;
        this.reloadLatest();
      }
    },
    editorOpen() {
      return this.inEditMode || Boolean(this.$refs.tinymce?.initializing);
    },
    enableNameEdit() {
      this.editingName = true;
    },
    disableNameEdit() {
      this.editingName = false;

      if (this.pendingRemoteReload) {
        this.pendingRemoteReload = false;
        this.reloadLatest();
      }
    },
    nameEditOpen() {
      return this.editingName && Boolean(this.$refs.nameInlineEdit?.editing);
    },
    reloadLatest() {
      if (!this.element.urls.show_url) return;

      this.reloadRequestSeq += 1;
      const requestSeq = this.reloadRequestSeq;

      axios.get(this.element.urls.show_url).then(({ data }) => {
        if (requestSeq !== this.reloadRequestSeq) return;

        if (this.editorOpen()) {
          this.pendingRemoteReload = true;
          if (!this.$refs.tinymce?.saving) this.compareWithEditorBase(data);
          return;
        }

        if (this.nameEditOpen()) {
          this.pendingRemoteReload = true;
          return;
        }

        const textViewChanged = data.text_view !== this.element.text_view;
        this.element.text = data.text;
        this.element.text_view = data.text_view;
        this.element.text_digest = data.text_digest;
        this.element.name = data.name;
        this.element.updated_at = data.updated_at;
        this.element.urls = data.urls;
        this.element.locked = data.locked;
        this.$emit('update', this.element, true);
        if (textViewChanged) this.$nextTick(this.refreshTextView);
      }).catch(() => {
        // Keep this here, because the text may have been deleted or moved
      });
    },
    checkForNewVersion() {
      this.pendingRemoteReload = true;
      const { tinymce } = this.$refs;
      if (!tinymce || tinymce.saving || !this.element.urls.show_url) return;

      // Shares reloadLatest's sequence, so an older response of either one never fires
      this.reloadRequestSeq += 1;
      const requestSeq = this.reloadRequestSeq;

      axios.get(this.element.urls.show_url).then(({ data }) => {
        if (requestSeq !== this.reloadRequestSeq || !this.editorOpen()) return;
        if (this.$refs.tinymce?.saving) return;

        this.compareWithEditorBase(data);
      }).catch(() => {
        // Keep this here, because the text may have been deleted or moved
      });
    },
    compareWithEditorBase(data) {
      const baseDigest = this.$refs.tinymce?.baseDigest;

      if (data.text_digest && data.text_digest !== baseDigest) {
        this.latestVersion = data;
        return;
      }

      // Check if name is beeing edited, and if so, update it to the latest version's name
      this.latestVersion = this.showingNewVersionModal ? data : null;
      if (!this.nameEditOpen()) this.element.name = data.name;
    },
    handleConflict(json) {
      if (!json || !json.latest) return;

      if (!this.editorOpen()) {
        this.latestVersion = null;
        this.pendingRemoteReload = false;
        this.reloadLatest();
        return;
      }

      this.latestVersion = json.latest;
      this.pendingRemoteReload = true;
      this.showingNewVersionModal = true;
    },
    onSaveFailed() {
      // A remote change deferred while our save was in flight isn't settled by a failed save
      if (this.editorOpen() && this.pendingRemoteReload) this.checkForNewVersion();
    },
    openNewVersionModal() {
      this.showingNewVersionModal = true;
      this.checkForNewVersion();
    },
    onNewVersionOverwrite(digest) {
      this.pendingOverwriteDigest = digest || null;
    },
    onNewVersionModalClose() {
      this.showingNewVersionModal = false;

      const digest = this.pendingOverwriteDigest;
      this.pendingOverwriteDigest = null;

      // A 409 on the overwrite comes back through handleConflict with the newer version
      if (digest && this.$refs.tinymce) {
        this.$refs.tinymce.overwrite(digest);
      } else {
        this.$refs.tinymce?.focusEditor();
      }
    },
    refreshTextView() {

      if (this.$refs.tinymce) {
        this.$refs.tinymce.wrapTables();
        this.$refs.tinymce.initCodeHighlight();
        return;
      }

      const textElement = this.$el.querySelector('.view-text-element');
      if (textElement) this.highlightText(textElement);
    },
    updateName(name) {
      this.element.name = name;
      axios.put(this.element.urls.update_url, {
        text_component: { name }
      }).then(() => {
        this.$emit('update', this.element, true);
      });
    },
    updateText(data) {
      this.element.text_view = data.attributes.text_view;
      this.element.text = data.attributes.text;
      this.element.text_digest = data.attributes.text_digest;
      this.element.name = data.attributes.name;
      this.element.updated_at = data.attributes.updated_at;
      this.$emit('update', this.element, true);
    },
    highlightText(textElToHighlight) {
      Prism.highlightAllUnder(textElToHighlight);
    }
  }
};
</script>
