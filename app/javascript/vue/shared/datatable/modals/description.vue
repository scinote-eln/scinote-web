<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" :title="object.name">
            {{ object.name }}
          </h4>
        </div>
        <div ref="description" class="modal-body">
          <div v-if="editMode">
            <TinymceEditor
              v-model="description"
              :placeholder="i18n.t('projects.index.add_description')"
              textareaId="descriptionModelInput"
            ></TinymceEditor>
          </div>
          <span v-else v-html="description"></span>
        </div>
        <div class="modal-footer">
          <button v-if="editMode" type="button" @click="cancelEdit" class="btn btn-secondary">{{ i18n.t('general.cancel') }}</button>
          <button v-else type="button" data-dismiss="modal" class="btn btn-secondary">{{ i18n.t('general.cancel') }}</button>
          <button v-if="object.permissions.manage && !editMode"
                  type="button"
                  @click="editMode = true"
                  class="btn btn-primary">
            {{ i18n.t('general.edit') }}
          </button>
          <button v-if="editMode"
                  type="button"
                  @click="updateDescription"
                  class="btn btn-primary">
            {{ i18n.t('general.save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import modalMixin from '../../modal_mixin';
import TinymceEditor from '../../tinymce_editor.vue';

export default {
  name: 'DescriptionModal',
  props: {
    object: Object
  },
  components: {
    TinymceEditor
  },
  data() {
    return {
      description: this.object.description,
      editMode: false
    };
  },
  created() {
    if (!this.object.description || this.object.description === '') {
      this.editMode = true;
    }
  },
  mounted() {
    this.$nextTick(() => {
      window.renderElementSmartAnnotations(this.$refs.description, 'span');
    });
  },
  mixins: [modalMixin],
  methods: {
    updateDescription() {
      this.$emit('update', this.description);
      this.$emit('close');
    },
    cancelEdit() {
      if (!this.object.description || this.object.description === '') {
        this.$emit('close');
      } else {
        this.editMode = false;
        this.description = this.object.description;
        this.$refs.description.classList.remove('sa-initialized');
        this.$nextTick(() => {
          window.renderElementSmartAnnotations(this.$refs.description, 'span');
        });
      }
    }
  }
};
</script>
