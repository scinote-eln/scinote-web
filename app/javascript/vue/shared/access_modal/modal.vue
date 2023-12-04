<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <component
          :is="mode"
          :params="params"
          :visible="visible"
          :default_role="default_role"
          @changeMode="changeMode"
          @modified="modified = true"
          @changeVisibility="changeVisibility"
        ></component>
      </div>
    </div>
  </div>
</template>

<script>

import SelectDropdown from "../../shared/select_dropdown.vue";
import axios from '../../../packs/custom_axios.js';
import modal_mixin from "../../shared/modal_mixin";
import editView from './edit.vue';
import newView from './new.vue';

export default {
  name: "AccessModal",
  props: {
    params: {
      type: Object,
      required: true
    },
  },
  mixins: [modal_mixin],
  components: {
    SelectDropdown,
    editView,
    newView
  },
  data() {
    return {
      mode: 'editView',
      modified: false,
      visible: false,
      default_role: null,
    };
  },
  mounted() {
    this.visible = !this.params.object.hidden;
    this.default_role = this.params.object.default_public_user_role_id;
  },
  beforeUnmount() {
    if (this.modified) {
      this.$emit('refresh');
    }
  },
  methods: {
    changeMode(mode) {
      this.mode = mode;
    },
    changeVisibility(status, role) {
      this.visible = status;
      this.default_role = role;
    },
  }
}
</script>
