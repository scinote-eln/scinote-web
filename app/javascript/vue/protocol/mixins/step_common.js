import axios from '../../../packs/custom_axios.js';
import {
  protocol_result_templates_path,
  my_module_results_path,
  user_setting_path
} from '../../../routes.js';

export default {
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
    removeElement(position) {
      this.elements.splice(position, 1);
      let unorderedElements = this.elements.map( e => {
        if (e.attributes.position >= position) {
          e.attributes.position -= 1;
        }
        return e;
      })
      this.$emit('stepUpdated')
    },
    attachmentDeleted(id) {
      this.attachments = this.attachments.filter((a) => a.id !== id );
      this.$emit('stepUpdated');
    },
    loadElements() {
      $.get(this.urls.elements_url, (result) => {
        this.elements = result.data
        this.$emit('step:elements:loaded');
      });
    },
    loadAttachments() {
      this.attachmentsReady = false;

      $.get(this.urls.attachments_url, (result) => {
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
      return my_module_results_path({my_module_id: this.step.attributes.my_module_id, result_id: result_id, view_mode: (archived ? 'archived' : 'active') });
    },
  }
};
