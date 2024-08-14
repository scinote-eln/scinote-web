<template>
  <div>
    <div :title="shareTitle" :data-html="true" data-toggle="tooltip" data-placement="left">
      <button class="btn"
              id="share-button"
              type="button"
              data-e2e="e2e-BT-tasks-shareTask"
              :class="[shareClass, {'disabled': !enabled}]"
              @click="openModal">
        <span class="sn-icon sn-icon-shared"></span>
        <span class="text-sm">
          {{ shareValue }}
        </span>
      </button>
    </div>
    <div ref="modal">
      <shareModalContainer :shared="share"
                           :open="visibleShareModal"
                           :shareableLinkUrl="shareableLinkUrl"
                           :characterLimit="255"
                           @enable="enableShare"
                           @disable="disableShare"
                           :canShare="canShare"
                           @close="closeModal"/>
    </div>
  </div>
</template>

<script>
import shareModalContainer from './components/shareable_link_modal.vue';

export default {
  name: 'ShareLinkContainer',
  components: { shareModalContainer },
  props: {
    shared: {
      type: Boolean,
      default: false
    },
    shareableLinkUrl: {
      type: String,
      required: true
    },
    canShare: {
      type: Boolean,
      default: false
    },
    enabled: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      share: false,
      visibleShareModal: false
    };
  },
  created() {
    this.share = this.shared;
  },
  computed: {
    shareClass() {
      return this.share ? 'btn-shared' : 'btn-secondary';
    },
    shareValue() {
      return this.i18n.t(this.share ? 'my_modules.shareable_links.shared' : 'my_modules.shareable_links.share');
    },
    shareTitle() {
      return this.enabled ? this.shareValue : this.i18n.t('my_modules.shareable_links.disabled');
    }
  },
  mounted() {
    // move modal to body to avoid z-index issues
    $('body').append($(this.$refs.modal));
    $('[data-toggle="tooltip"]').tooltip();
  },
  methods: {
    enableShare() {
      this.share = true;
    },
    disableShare() {
      this.share = false;
    },
    openModal() {
      this.visibleShareModal = true;
    },
    closeModal() {
      this.visibleShareModal = false;
    }
  }
};
</script>
