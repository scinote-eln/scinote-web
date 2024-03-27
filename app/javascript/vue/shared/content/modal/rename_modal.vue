<template>
  <div ref="modal" @keydown.esc="close" class="modal" id="renameAttachmentModal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-md" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t('assets.rename_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('assets.from_clipboard.file_name')}}</p>
          <div class="sci-input-container" :class="{ 'error': error }" :data-error-text="error">
            <input ref="input" v-model="name" type="text" class="sci-input-field" @keyup.enter="renameAttachment(name)" required="true" />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="close">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="renameAttachment(name)" :disabled="error">{{ this.i18n.t('assets.context_menu.rename') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from '../../modal_mixin';
import axios from '../../../../packs/custom_axios.js';

export default {
  name: 'RenameAttachmentModal',
  mixins: [modalMixin],
  props: {
    url_path: {
      type: String,
      required: true
    },
    fileName: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      name: null,
      error: null
    };
  },
  created() {
    this.name = this.fileName;
  },
  watch: {
    name() {
      this.validateName();
    }
  },
  methods: {
    validateName() {
      if (!this.name || this.name.length === 0) {
        this.error = this.i18n.t('assets.rename_modal.min_length_error');
      } else if (this.name.length > 255) {
        this.error = this.i18n.t('assets.rename_modal.max_length_error');
      } else {
        this.error = null;
        return true;
      }
      return false;
    },
    async renameAttachment(newName) {
      if (!this.validateName()) {
        return;
      }

      const payload = { asset: { name: newName } };

      try {
        const response = await axios.patch(this.url_path, payload);
        this.$emit('attachment:update', response.data.data);
        this.close();
      } catch (error) {
        if (error.response) {
          this.error = error.response.data.errors || error.response.statusText;
        } else {
          this.error = error.message;
        }
      }
    }
  }
};
</script>
