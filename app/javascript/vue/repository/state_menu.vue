<template>
  <MenuDropdown
    :listItems="viewModesMenu"
    :btnClasses="'btn btn-secondary !border-sn-light-grey px-3 prevent-shrink' + disabled"
    :btnText="btnText"
    :caret="true"
    position='right'>
  </MenuDropdown>
</template>

<script>
/* global I18n */
import MenuDropdown from '../shared/menu_dropdown.vue';

export default {
  components: {
    MenuDropdown
  },
  name: 'RepositoryStateMenu',
  props: {
    viewMode: { type: String, required: true },
    activeUrl: { type: String, required: true },
    archivedUrl: { type: String, required: true },
    disabled: { type: String, default: 'false' }
  },
  beforeUnmount() {
    delete window.initRepositoryStateMenu;
  },
  computed: {
    disabled() {
      return this.disabled === 'true' ? ' disabled' : '';
    },
    btnText() {
      return I18n.t(`toolbar.${this.viewMode}_state`);
    },
    viewModesMenu() {
      return [
        {
          text: I18n.t('toolbar.active_state'),
          active: this.viewMode === 'active',
          url: this.activeUrl
        },
        {
          text: I18n.t('toolbar.archived_state'),
          active: this.viewMode === 'archived',
          url: this.archivedUrl
        }
      ];
    }

  }
};
</script>
