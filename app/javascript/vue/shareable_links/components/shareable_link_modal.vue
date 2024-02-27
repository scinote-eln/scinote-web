<template>
  <div>
    <div
      ref="modal"
      class="modal fade share-task-modal centered-modal"
      id="share-task-modal"
      tabindex="-1"
      role="dialog"
      aria-labelledby="shareTaskModalLabel"
    >
      <div class="modal-dialog" role="document">
        <div class="modal-content">
          <div class="modal-header flex">
            <button
              type="button"
              class="close float-right !ml-auto"
              data-dismiss="modal"
              tabindex="0"
              aria-label="Close"
            >
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title">
              {{ i18n.t("shareable_links.modal.title") }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="flex items-center text-sm gap-4 mb-4">
              <span>{{ i18n.t("shareable_links.modal.sharing_toggle_label") }}</span>
              <span class="sci-toggle-checkbox-container">
                <input type="checkbox"
                      v-model="sharedEnabled"
                      id="checkbox"
                      class="sci-toggle-checkbox"
                      :disabled="!canShare"
                      tabindex="0"
                      @click.prevent="checkboxChange"
                      @keyup.enter="checkboxChange"/>
                <span class="sci-toggle-checkbox-label"></span>
              </span>
            </div>
            <div class="text-sm">
              <div class="sci-input-container-v2 textarea-lg mb-2">
                <textarea ref="textarea"
                          tabindex="0"
                          class="sci-input-field"
                          :class="{ 'error': error }"
                          v-model="description"
                          :placeholder="i18n.t('shareable_links.modal.description_placeholder')"
                          :disabled="!sharedEnabled || !canShare"
                          @focus="editing = true">
                </textarea>
              </div>
              <div v-if="error" class="text-xs shareable-link-error">
                {{ error }}
              </div>

              <div class="mb-2" v-if="editing">
                <div class="sci-btn-group flex justify-end">
                  <button class="btn btn-secondary btn-sm" tabindex="0" @mousedown="cancelDescriptionEdit">{{ i18n.t('general.cancel') }}</button>
                  <button class="btn btn-secondary btn-sm" tabindex="0" @mousedown="saveDescription" :disabled="error">{{ i18n.t('general.save') }}</button>
                </div>
              </div>
            </div>

            <div>
              <div class="mb-2"> {{ i18n.t('shareable_links.modal.sharing_link_label') }} </div>
              <div class="sci-input-container-v2 input-sm text-sm mb-2 flex-row-reverse">
                <input type="text"
                        class="sci-input-field !pr-16"
                        ref="clone"
                        :value="shareableData.attributes ? shareableData.attributes.shareable_url : ''"
                        id="#share-link-input"
                        :disabled="true"
                  />
                  <button class="btn btn-primary btn-sm share-link-copy"
                          tabindex="0"
                          @click="copy($refs.clone.value)"
                          :disabled="!sharedEnabled">{{ i18n.t('shareable_links.modal.copy_button') }}
                  </button>
              </div>
              <div v-if="sharedEnabled" class="text-xs shareable-link-disclaimer"> {{ i18n.t('shareable_links.modal.disclaimer') }} </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <deleteShareableLinkModal v-if="confirmingDelete" @confirm="deleteLink" @cancel="closeDeleteModal"/>
  </div>
</template>

<script>
import deleteShareableLinkModal from './delete_shareable_link.vue';

export default {
  name: 'shareModalContainer',
  components: { deleteShareableLinkModal },
  props: {
    open: {
      type: Boolean,
      required: true
    },
    shared: {
      type: Boolean,
      default: false
    },
    shareableLinkUrl: {
      type: String,
      required: true
    },
    characterLimit: {
      type: Number,
      default: null
    },
    canShare: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      editing: false,
      shareableData: {},
      description: '',
      sharedEnabled: false,
      characterCount: 0,
      confirmingDelete: false,
      dirty: false
    };
  },
  watch: {
    shared() {
      this.sharedEnabled = this.shared;
    },
    open() {
      this.open ? this.showModal() : this.hideModal();
    }
  },
  mounted() {
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      if (!this.confirmingDelete) {
        this.$emit('close');
      }
    });
  },
  created() {
    this.sharedEnabled = this.shared;
    if (this.sharedEnabled) {
      $.get(this.shareableLinkUrl, (result) => {
        this.shareableData = result.data;
        this.description = this.shareableData.attributes.description || '';
        this.$nextTick(() => {
          this.initCharacterCount();
        });
      });
    }
  },
  computed: {
    error() {
      if (this.characterLimit && this.description.length > this.characterLimit) {
        return this.i18n.t('shareable_links.modal.too_long_text', { counter: this.characterLimit });
      }
      return false;
    }
  },
  methods: {
    showModal() {
      $(this.$refs.modal).modal('show');
    },
    hideModal() {
      $(this.$refs.modal).modal('hide');
    },
    copy(value) {
      navigator.clipboard.writeText(value).then(
        () => {
          HelperModule.flashAlertMsg(this.i18n.t('shareable_links.modal.copy_success'), 'success');
        }
      );
    },
    saveDescription() {
      this.dirty = true;
      $.ajax({
        url: this.shareableLinkUrl,
        type: 'PATCH',
        data: { description: this.description },
        success: (result) => {
          this.shareableData = result.data;
          this.dirty = false;
          this.editing = false;
        }
      });
    },
    cancelDescriptionEdit() {
      this.description = this.shareableData.attributes.description || '';
      this.editing = false;
    },
    initCharacterCount() {
      $(this.$refs.textarea).on('input change paste keydown', () => {
        this.characterCount = this.$refs.textarea.value.length;
      });
    },
    checkboxChange() {
      if (!this.sharedEnabled) {
        $.post(this.shareableLinkUrl, { description: this.description }, (result) => {
          this.shareableData = result.data;
          this.$emit('enable');
          this.copy(this.shareableData.attributes.shareable_url);
        });
      } else {
        this.hideModal();
        this.confirmingDelete = true;
      }
    },
    deleteLink() {
      this.dirty = true;
      $.ajax({
        url: this.shareableLinkUrl,
        type: 'DELETE',
        success: () => {
          this.shareableData = {};
          this.description = '';
          this.dirty = false;
          this.sharedEnabled = false;

          this.$emit('disable');
          this.$emit('close');
        },
        error: () => {
          this.dirty = false;
        }
      });
    },
    closeDeleteModal() {
      this.confirmingDelete = false;
      if (!this.dirty) {
        this.$emit('close');
      }
    }
  }
};
</script>
