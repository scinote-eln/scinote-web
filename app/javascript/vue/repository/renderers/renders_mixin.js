import { vOnClickOutside } from '@vueuse/components';

export default {
  props: {
    params: {
      required: true
    }
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  computed: {
    updateUrl() {
      return this.params.data.urls.update && !this.params.colDef.readOnly;
    }
  }
};
