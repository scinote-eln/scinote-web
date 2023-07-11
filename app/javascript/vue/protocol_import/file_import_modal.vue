<template>
  <div ref="modal" class="modal fade" id="protcolFileImportModal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal">&times;</button>
        <h4 class="modal-title">{{ i18n.t(`protocols.import_modal.${state}.title`) }}</h4>
        </div>
        <div class="modal-body text-xs" v-html="i18n.t(`protocols.import_modal.${state}.body_html`, { url: protocolUrl })">
        </div>
        <div class="modal-footer">
          <button type="button"
                  class="btn btn-default"
                  data-dismiss="modal">{{ i18n.t('protocols.import_modal.cancel') }}</button>

          <button v-if="state === 'confirm'" type="button"
                  class="btn btn-primary"
                  @click.stop.prevent="confirm">{{ i18n.t('protocols.import_modal.import') }}</button>
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
      importUrl: { type: String, required: true}
    },
    data() {
      return {
        state: "confirm",
        files: null,
        jobPollInterval: null,
        pollCount: 0,
        jobId: null,
        protocolUrl: null,
        refreshCallback: null
      }
    },
    mounted() {
      window.protocolFileImportModal = this;
    },
    methods: {
      open() {
        $(this.$refs.modal).modal('show');
      },
      close() {
        if (this.state === "done" && this.refreshCallback) {
          this.refreshCallback();
        }
        $(this.$refs.modal).modal('hide');
      },
      init(files, refreshCallback) {
        this.refreshCallback = refreshCallback;
        this.pollCount = 0;
        this.jobId = null;
        this.files = files;
        this.state = "confirm";
        this.open();
      },
      confirm() {
        $.post(this.importUrl, (data) => {
          this.state = 'in_progress';
          this.jobId = data.job_id
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
          let status = data.status;

          console.log(data)

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
              clearInterval(this.jobPollInterval);
              break;
          }
        });
      }
    }
  }
</script>
