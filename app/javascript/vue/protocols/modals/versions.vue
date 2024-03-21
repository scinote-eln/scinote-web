<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block">
            {{ i18n.t('protocols.index.versions.title', { protocol: protocol.name }) }}
          </h4>
        </div>
        <div class="modal-body">
          <div v-if="updating" class="flex absolute top-0 items-center justify-center w-full flex-grow h-full z-10">
            <img src="/images/medium/loading.svg" alt="Loading" class="p-4 rounded-xl bg-sn-white" />
          </div>
          <div class="max-h-[400px] overflow-y-auto">
            <div v-if="draft">
              <div class="flex items-center gap-4">
                <a :href="draft.urls.show" class="hover:no-underline cursor-pointer shrink-0">
                  <span v-if="draft.previous_number"
                        v-html="i18n.t('protocols.index.versions.draft_html', {
                          parent_version: draft.previous_number
                        })"
                  ></span>
                  <span v-else v-html="i18n.t('protocols.index.versions.first_draft_html')"></span>
                </a>
                <span class="text-xs" v-if="draft.modified_by">
                  {{
                      i18n.t('protocols.index.versions.draft_full_modification_info', {
                        modified_on: draft.modified_on,
                        modified_by: draft.modified_by
                      })
                  }}
                </span>
                <span class="text-xs" v-else>
                  {{
                      i18n.t('protocols.index.versions.draft_update_modification_info', {
                        modified_on: draft.modified_on
                      })
                  }}
                </span>
                <div class="flex items-center gap-2 ml-auto">
                  <button v-if="draft.urls.publish" class="btn btn-light" :disabled="updating" @click="publishDraft">
                    {{ i18n.t('protocols.index.versions.publish') }}
                  </button>
                  <button v-if="draft.urls.destroy" @click="destroyDraft" :disabled="updating" class="btn btn-light icon-btn">
                    <i class="sn-icon sn-icon-delete"></i>
                  </button>
                </div>
              </div>
              <InlineEdit
                  :class="{ 'pointer-events-none': !draft.urls.comment }"
                  class="mb-4"
                  :value="draft.comment"
                  :characterLimit="10000"
                  :placeholder="i18n.t('protocols.index.versions.comment_placeholder')"
                  :allowBlank="true"
                  :singleLine="false"
                  :attributeName="`${i18n.t('Draft')} ${i18n.t('comment')}`"
                  @update="updateComment"
                />
            </div>
            <div v-for="version in publishedVersions" :key="version.number">
              <div class="flex items-center gap-4 group min-h-[40px]">
                <a :href="version.urls.show" class="hover:no-underline cursor-pointer shrink-0">
                  <b>
                    {{ i18n.t('protocols.index.versions.revision', { version: version.number }) }}
                  </b>
                </a>
                <span class="text-xs">
                  {{
                      i18n.t('protocols.index.versions.revision_publishing_info', {
                        published_on: version.published_on,
                        published_by: version.published_by
                      })
                  }}
                </span>
                <button
                  v-if="version.urls.save_as_draft"
                  class="btn btn-light icon-btn ml-auto tw-hidden group-hover:flex"
                  :title="i18n.t('protocols.index.versions.save_as_draft')"
                  @click="saveAsDraft(version.urls.save_as_draft)"
                  :disabled="draft || updating"
                >
                  <i class="sn-icon sn-icon-duplicate"></i>
                </button>
              </div>
              <div class="mb-4">
                {{  version.comment }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <ConfirmationModal
    :title="i18n.t('protocols.delete_draft_modal.title')"
    :description="`
      <p>${i18n.t('protocols.delete_draft_modal.description_1')}</p>
      <p><b>${i18n.t('protocols.delete_draft_modal.description_2')}</b></p>
    `"
    :confirmClass="'btn btn-danger'"
    :confirmText="i18n.t('protocols.delete_draft_modal.confirm')"
    ref="destroyModal"
  ></ConfirmationModal>
</template>

<script>

/* global HelperModule */

import SelectDropdown from '../../shared/select_dropdown.vue';
import InlineEdit from '../../shared/inline_edit.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import ConfirmationModal from '../../shared/confirmation_modal.vue';

export default {
  name: 'VersionsModal',
  props: {
    protocol: {
      required: true,
      typr: Object
    }
  },
  emits: ['refresh', 'close', 'reloadPage', 'redirectToProtocols'],
  mixins: [modalMixin],
  components: {
    SelectDropdown,
    InlineEdit,
    ConfirmationModal
  },
  data() {
    return {
      draft: null,
      publishedVersions: [],
      updating: false
    };
  },
  mounted() {
    this.loadModalData();
  },
  methods: {
    loadModalData() {
      axios.get(this.protocol.urls.versions_modal).then((response) => {
        this.publishedVersions = response.data.versions;
        this.draft = response.data.draft;
      });
    },
    updateComment(comment) {
      axios.put(this.draft.urls.comment, { protocol: { version_comment: comment } }).then(() => {
        this.draft.comment = comment;
      });
    },
    async destroyDraft() {
      const ok = await this.$refs.destroyModal.show();
      if (ok) {
        if (this.updating) return;
        this.updating = true;
        axios.post(this.draft.urls.destroy, {
          version_modal: true
        }).then((response) => {
          document.body.style.overflow = 'hidden';
          this.$emit('refresh');
          this.$emit('redirectToProtocols');
          this.loadModalData();
          HelperModule.flashAlertMsg(response.data.message, 'success');
          this.updating = false;
        });
      } else {
        document.body.style.overflow = 'hidden';
      }
    },
    saveAsDraft(url) {
      if (this.updating) {
        return;
      }

      this.updating = true;
      axios.post(url).then((response) => {
        window.location.href = response.data.url;
      }).catch((error) => {
        this.updating = false;
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    publishDraft() {
      if (this.updating) return;
      this.updating = true;

      axios.post(this.draft.urls.publish).then(() => {
        this.loadModalData();
        this.$emit('refresh');
        this.updating = false;
      });
    }
  }
};
</script>
