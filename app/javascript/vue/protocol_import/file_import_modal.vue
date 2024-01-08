<template>
  <div ref="modal" class="modal fade" id="protcolFileImportModal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" :aria-label="i18n.t('general.close')">
            <i class="sn-icon sn-icon-close"></i>
          </button>
        <h4 class="modal-title">{{ i18n.t(`protocols.import_modal.${state}.title`) }}</h4>
        </div>
        <div class="modal-body text-sm" v-html="i18n.t(`protocols.import_modal.${state}.body_html`, { url: protocolTemplateTableUrl })">
        </div>
        <div class="modal-footer">
          <button v-if="state === 'confirm'" type="button"
                  class="btn btn-primary"
                  @click.stop.prevent="confirm">{{ i18n.t('protocols.import_modal.import') }}</button>
          <button v-else-if="state === 'failed'" type="button"
                  class="btn btn-primary"
                  data-dismiss="modal">{{ i18n.t('protocols.import_modal.close') }}</button>
          <button v-else type="button"
                  class="btn btn-primary"
                  :disabled="state === 'in_progress'"
                  @click.stop.prevent="close">{{ i18n.t('protocols.import_modal.close') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ProtocolFileImportModal',
  props: {
    importUrl: { type: String, required: true },
    protocolTemplateTableUrl: { type: String }
  },
  data() {
    return {
      state: 'confirm',
      files: null,
      jobPollInterval: null,
      pollCount: 0,
      jobId: null,
      refreshCallback: null
    };
  },
  mounted() {
    window.protocolFileImportModal = this;
  },
  methods: {
    open() {
      $('.protocol-import-dropdown-button').dropdown('toggle');
      $(this.$refs.modal).modal('show');
    },
    close() {
      if (this.state === 'done' && this.refreshCallback) {
        this.refreshCallback();
      }
      $(this.$refs.modal).modal('hide');
    },
    init(files, refreshCallback) {
      this.refreshCallback = refreshCallback;
      this.pollCount = 0;
      this.jobId = null;
      this.files = files;
      this.state = 'confirm';
      this.open();
    },
    confirm() {
      const formData = new FormData();
      Array.from(this.files).forEach((file) => formData.append('files[]', file, file.name));

      $.post({
        url: this.importUrl, data: formData, processData: false, contentType: false
      }, (data) => {
        this.state = 'in_progress';
        this.jobId = data.job_id;
        this.jobPollInterval = setInterval(this.fetchJobStatus, 1000);
      });
    },
    fetchJobStatus() {
      this.pollCount += 1;

      if (this.pollCount > 4) {
        this.state = 'not_yet_done';
        clearInterval(this.jobPollInterval);
        return;
      }

      $.get(`/jobs/${this.jobId}/status`, (data) => {
        const { status } = data;

        switch (status) {
          case 'pending':
            break;
          case 'running':
            break;
          case 'done':
            this.state = 'done';
            clearInterval(this.jobPollInterval);
            break;
          case 'failed':
            this.state = 'failed';
            clearInterval(this.jobPollInterval);
            break;
        }
      });
    }
  }
};
</script>
