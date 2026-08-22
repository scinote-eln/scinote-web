import axios from '../../../packs/custom_axios.js';
import {
  protocol_result_templates_path,
  my_module_results_path,
  archive_my_module_path,
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
      return this.step.attributes.urls || {};
    }
  },
  watch: {
    step: {
      handler(newVal) {
        if (this.isCollapsed !== newVal.attributes.collapsed) {
          this.toggleCollapsed();
        }
      },
      deep: true
    }
  },
  created() {
    this.elements = this.step.elements;
    this.attachments = this.step.attachments;

    if (this.attachments.findIndex((e) => e.attributes.attached === false) >= 0) {
      setTimeout(() => {
        this.loadAttachments();
      }, 10000);
    }
  },
  mounted() {
    this.$nextTick(() => {
      const stepId = `#stepBody${this.step.id}`;
      this.isCollapsed = this.step.attributes.collapsed;
      if (this.isCollapsed) {
        $(stepId).collapse('hide');
      } else {
        $(stepId).collapse('show');
      }
      this.$emit('step:collapsed');
    });
  },
  methods: {
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;

      this.step.attributes.collapsed = this.isCollapsed;

      const settings = {
        value: { [this.step.id]: this.isCollapsed }
      };

      this.$emit('step:collapsed');
      axios.put(user_setting_path('task_step_states'), {user_setting: settings});
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
        this.$emit('step:empty', this.step.id);
      }

      this.$emit('stepUpdated');
    },
    attachmentDeleted(id) {
      this.attachments = this.attachments.filter((a) => a.id !== id );
      if(this.elements.length === 0 && this.attachments.length === 0) {
        this.$emit('step:empty', this.step.id);
      }
      this.$emit('stepUpdated');
    },
    loadElements() {
      axios.get(this.urls.elements_url).then((response) => {
        const result = response.data;
        this.elements = result.data;
        this.$emit('step:elements:loaded');
      });
    },
    loadAttachments() {
      this.attachmentsReady = false;

      axios.get(this.urls.attachments_url).then((response) => {
        const result = response.data;
        this.attachments = result.data
        this.$emit('step:attachments:loaded');
        if (this.attachments.findIndex((e) => e.attributes.attached === false) >= 0) {
          setTimeout(() => {
            this.loadAttachments();
          }, 10000)
        } else {
          this.attachmentsReady = true;
        }
      });
      this.showFileModal = false;
    },
    resultUrl(result_id, archived) {
      if (!this.step.attributes.my_module_id) {
        return protocol_result_templates_path({protocol_id: this.step.attributes.protocol_id, result_id: result_id });
      }

      if (archived) {
        return archive_my_module_path(this.step.attributes.my_module_id, { result_id: result_id, mode: 'results' });
      } else {
        return my_module_results_path({my_module_id: this.step.attributes.my_module_id, result_id: result_id });
      }
    },
  }
};
