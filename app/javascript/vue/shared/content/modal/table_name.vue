<template>
  <div ref="modal" class="modal" :id="`tableNameModal${element.attributes.orderable.id}`" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-md" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" @click="cancel" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title" id="modal-table-name">
            {{ i18n.t('protocols.steps.table.name_modal.title')}}
          </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('protocols.steps.table.name_modal.description')}}</p>
          <div class="sci-input-container" :class="{ 'error': error }">
            <input ref="input" v-model="name" type="text" class="sci-input-field" @keyup.enter="!error && update(name)" required="true" />
            <div v-if="error" class="table-name-error">
              {{ i18n.t('protocols.steps.table.name_modal.error') }}
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancel">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="update(name)">{{ i18n.t('protocols.steps.table.name_modal.save')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TableNameModal',
  props: {
    element: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      name: null
    };
  },
  computed: {
    defaultName() {
      return this.i18n.t('protocols.steps.table.default_name', { position: this.element.attributes.position + 1 });
    },
    error() {
      return !this.name;
    }
  },
  mounted() {
    this.initModal();
    $(this.$refs.modal).modal('show');
  },
  methods: {
    initModal() {
      this.name = this.defaultName;
      $(this.$refs.modal).on('shown.bs.modal', () => {
        $(this.$refs.input).focus();
      });
    },
    cancel() {
      this.hide(() => {
        this.$emit('cancel');
      });
    },
    update() {
      this.hide(() => {
        this.$emit('update', this.name);
      });
    },
    hide(callback) {
      $(this.$refs.modal).on('hidden.bs.modal', () => {
        callback();
      });
      $(this.$refs.modal).modal('hide');
    }
  }
};
</script>
