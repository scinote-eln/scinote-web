<template>
  <div class="p-4 w-full rounded bg-sn-light-grey min-h-[68px]" data-e2e="e2e-CO-actionToolbar">
    <div class="flex gap-4 items-center h-full">
      <div v-if="loading && !actions.length" class="sn-action-toolbar__action">
        <a class="rounded flex items-center py-1.5 px-2.5 bg-transparent text-transparent no-underline"></a>
      </div>
      <div v-if="!loading && actions.length === 0" class="text-sn-grey-grey">
        {{ i18n.t('action_toolbar.no_actions') }}
      </div>
      <div v-for="action in actions" :key="action.name" class="sn-action-toolbar__action shrink-0">
        <a :class="`rounded flex gap-2 items-center py-1.5 px-1.5 xl:px-2.5 hover:text-sn-white hover:bg-sn-blue
                  bg-sn-white color-sn-blue hover:no-underline focus:no-underline ${action.button_class}`"
          :href="(['link', 'remote-modal']).includes(action.type) ? action.path : '#'"
          :id="action.button_id"
          :title="action.label"
          :data-e2e="`e2e-BT-actionToolbar-${action.name}`"
          @click="doAction(action, $event)">
          <i :class="action.icon"></i>
          <span class="tw-hidden xl:inline-block">{{ action.label }}</span>
        </a>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ActionToolbar',
  props: {
    actionsUrl: { type: String, required: true },
    params: { type: Object },
  },
  data() {
    return {
      actions: [],
      multiple: false,
      reloadCallback: null,
      loaded: false,
      loading: true,
    };
  },
  watch: {
    params() {
      this.loadActions();
    },
  },
  created() {
    this.loadActions();
  },
  methods: {
    loadActions() {
      this.loading = true;
      this.loaded = false;
      $.get(`${this.actionsUrl}?${new URLSearchParams(this.params).toString()}`, (data) => {
        this.actions = data.actions;
        this.loading = false;
        this.loaded = true;
      });
    },
    doAction(action, event) {
      switch (action.type) {
        case 'emit':
          event.preventDefault();
          this.$emit('toolbar:action', action);
          // do nothing, this is handled by legacy code based on the button class
          break;
        case 'link':
          // do nothing, already handled by href
          break;
        default:
          break;
      }
    },
  },
};
</script>
