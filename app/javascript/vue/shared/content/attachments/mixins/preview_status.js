import consumer from '../../../../../channels/consumer';

const READY = 'ready';
const PROCESSING = 'processing';
const FAILED = 'failed';

export default {
  data() {
    return {
      previewStatus: this.attachment.attributes.preview_status,
      previewLoaded: false,
      previewSubscription: null
    };
  },
  computed: {
    previewProcessing() {
      return this.previewStatus === PROCESSING;
    },
    previewFailed() {
      return this.previewStatus === FAILED;
    },
    previewVisible() {
      return this.previewLoaded;
    },
    previewLoading() {
      return this.previewProcessing || (this.previewSrc !== null && !this.previewLoaded);
    },
    previewSrc() {
      if (this.previewStatus !== READY) return null;

      return this.attachment.attributes.medium_preview;
    }
  },
  watch: {
    'attachment.attributes.preview_status'(status) {
      this.setPreviewStatus(status);
    }
  },
  mounted() {
    if (this.previewProcessing) this.subscribePreview();
  },
  beforeUnmount() {
    this.unsubscribePreview();
  },
  methods: {
    onPreviewLoad() {
      this.previewLoaded = true;
    },
    onPreviewError() {
      if (this.previewFailed) return;

      this.setPreviewStatus(PROCESSING);
    },
    setPreviewStatus(status) {
      this.previewStatus = status;

      if (status !== PROCESSING) return;

      this.previewLoaded = false;
      this.subscribePreview();
    },
    subscribePreview() {
      if (this.previewSubscription) return;

      this.previewSubscription = consumer.subscriptions.create(
        { channel: 'AssetPreviewChannel', asset_id: this.attachment.id },
        {
          received: (data) => this.setPreviewStatus(data.status),
          rejected: () => this.unsubscribePreview()
        }
      );
    },
    unsubscribePreview() {
      if (!this.previewSubscription) return;

      consumer.subscriptions.remove(this.previewSubscription);
      this.previewSubscription = null;
    }
  }
};
