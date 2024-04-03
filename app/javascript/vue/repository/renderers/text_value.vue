<template>
  <div>
    <div
      v-if="!editMode"
      @click="startEdit($event)"
      v-html="textValue.value.view || placeholder"
      class="truncate cursor-pointer pl-[3px] w-full"
      :class="{'h-9 text-sn-grey': textValue.value.view.length == 0}"
    ></div>
    <div v-if="editMode" v-click-outside="finishEdit">
      <input ref="input" type="text" :value="textValue.value.edit" class="h-9 w-full focus:outline-0 border border-solid !border-sn-science-blue"/>
    </div>
  </div>
</template>

<script>
/* global SmartAnnotation */
import rendersMixin from './renders_mixin.js';
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'TextValue',
  mixins: [rendersMixin],
  mounted() {
    if (this.params.value) {
      this.textValue = this.params.value;
    }
  },
  data() {
    return {
      editMode: false,
      textValue: {
        value: {
          view: '',
          edit: ''
        }
      }
    };
  },
  computed: {
    placeholder() {
      return this.updateUrl ? 'Enter text' : '';
    }
  },
  methods: {
    startEdit(e) {
      const { target } = e;

      if (target?.tagName === 'A' || !this.updateUrl) {
        return;
      }
      this.editMode = true;
      this.$nextTick(() => {
        this.$refs.input.focus();
        SmartAnnotation.init($(this.$refs.input), false);
      });
    },
    finishEdit(e) {
      const { target } = e;
      if ($(target).closest('.atwho-view').length) {
        return;
      }
      this.$nextTick(() => {
        this.updateCell();
      });
    },
    updateCell() {
      const newValue = this.$refs.input.value;

      if (newValue === this.textValue.value.edit) {
        this.editMode = false;
        return;
      }

      const updateUrl = this.params.data.urls.update;
      const params = { repository_cells: {} };
      params.repository_cells[this.params.colDef.columnId] = this.$refs.input.value;
      axios.put(updateUrl, params).then((response) => {
        this.textValue.value = response.data.value || { view: '', edit: '' };
        this.editMode = false;
      });
    }
  }
};
</script>
