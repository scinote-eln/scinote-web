import axios from '../../../packs/custom_axios.js';
import {
  protocols_my_module_path,
  protocol_path,
  user_setting_path
} from '../../../routes.js';

export default {
  data() {
    return {
      elements: [],
      attachments: [],
      attachmentsReady: true,
      confirmingDelete: false,
      isCollapsed: false
    };
  },
  computed: {
    orderedElements() {
      return this.elements.sort((a, b) => a.attributes.position - b.attributes.position);
    },
    urls() {
      return this.result.attributes.urls || {};
    },
    locked() {
      return !(this.urls.restore_url || this.urls.archive_url || this.urls.delete_url || this.urls.update_url);
    }
  },
  watch: {
    resultToReload() {
      if (Number(this.resultToReload) === Number(this.result.id)) {
        this.loadElements();
        this.loadAttachments();
      }
    },
    result: {
      handler(newVal) {
        if (this.isCollapsed !== newVal.attributes.collapsed) {
          this.toggleCollapsed();
        }
      },
      deep: true
    }
  },
  created() {
    this.elements = this.result.elements;
    this.attachments = this.result.attachments;

    if (this.attachments.findIndex((e) => e.attributes.attached === false) >= 0) {
      setTimeout(() => {
        this.loadAttachments();
      }, 10000);
    }
  },
  mounted() {
    this.$nextTick(() => {
      const resultId = `#resultBody${this.result.id}`;
      this.isCollapsed = this.result.attributes.collapsed;
      if (this.isCollapsed) {
        $(resultId).collapse('hide');
      } else {
        $(resultId).collapse('show');
      }
      this.$emit('result:collapsed');
    });

    window.initTooltip(this.$refs.linkButton);
  },
  beforeUnmount() {
    window.destroyTooltip(this.$refs.linkButton);
  },
  methods: {
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
      this.result.attributes.collapsed = this.isCollapsed;

      const stateKey = this.result.attributes.type == "ResultTemplate" ? 'result_template_states' : 'result_states';

      const settings = {
        value: { [this.result.id]: this.isCollapsed }
      };

      axios.put(user_setting_path(stateKey), {user_setting: settings});

      this.$emit('result:collapsed');
    },
    removeElement(id) {
      const position = this.elements.find(el => el.id == id)?.attributes?.position;

      this.elements = this.elements
                          .filter(el => el.id !== id)
                          .map(el => {
                            if (el.attributes.position >= position) {
                              el.attributes.position--;
                            }
                            return el;
                          });

      if (!this.elements.length && !this.attachments.length) {
        this.$emit('result:empty', this.result.id);
      }

      this.$emit('resultUpdated');
    },
    attachmentDeleted(id) {
      this.attachments = this.attachments.filter((a) => a.id !== id);
      if(this.elements.length === 0 && this.attachments.length === 0) {
        this.$emit('result:empty', this.result.id);
      }
      this.$emit('resultUpdated');
    },
    loadElements() {
      $.get(this.urls.elements_url, (result) => {
        this.elements = result.data;
        this.$emit('result:elements:loaded');
      });
    },
    loadAttachments() {
      this.attachmentsReady = false;

      $.get(this.urls.attachments_url, (result) => {
        this.attachments = result.data;
        this.$emit('result:attachments:loaded');
        if (this.attachments.findIndex((e) => e.attributes.attached === false) >= 0) {
          setTimeout(() => {
            this.loadAttachments();
          }, 10000);
        } else {
          this.attachmentsReady = true;
        }
      });
      this.showFileModal = false;
    },
    protocolUrl(step_id) {
      if (this.result.attributes.protocol_id) {
        return protocol_path({ id: this.result.attributes.protocol_id }, { step_id: step_id });
      }
      return protocols_my_module_path({ id: this.result.attributes.my_module_id }, { step_id: step_id })
    },
    deleteResult() {
      axios.delete(this.urls.delete_url).then((response) => {
        this.$emit('result:deleted', this.result.id);
      });
    }
  }
};
