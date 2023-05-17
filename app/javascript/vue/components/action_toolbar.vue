<template>
  <div v-if="loading || actions.length" class="sn-action-toolbar p-4 w-full fixed bottom-0 rounded-t-md shadow-[0_-12px_24px_-12px_rgba(35,31,32,0.2)]" :style="`width: ${width}px`">
    <div class="sn-action-toolbar__actions flex">
      <div v-if="loading && !actions.length" class="sn-action-toolbar__action">
        <a class="btn btn-light"></a>
      </div>
      <div v-for="action in actions" :key="action.name" class="sn-action-toolbar__action">
        <a :class="`btn btn-light ${action.button_class}`"
          :href="(['link', 'remote-modal']).includes(action.type) ? action.path : '#'"
          :id="action.button_id"
          :data-url="action.path"
          :data-object-type="action.item_type"
          :data-object-id="action.item_id"
          :data-action="action.type"
          @click="doAction(action)">
          <i class="mr-1" :class="action.icon"></i>
          {{ action.label }}
        </a>
      </div>
    </div>
  </div>
</template>

<script>
  import {debounce} from '../shared/debounce.js';

  export default {
    name: 'ActionToolbar',
    props: {
      actionsUrl: { type: String, required: true }
    },
    data() {
      return {
        actions: [],
        shown: false,
        multiple: false,
        params: {},
        reloadCallback: null,
        loading: false,
        width: 0
      }
    },
    created() {
      window.actionToolbarComponent = this;
      window.onresize = this.setWidth;

      this.debouncedFetchActions = debounce((params) => {
        this.params = params;

        $.get(`${this.actionsUrl}?${new URLSearchParams(this.params).toString()}`, (data) => {
          this.actions = data.actions;
          this.loading = false;
        });
      }, 200);
    },
    mounted() {
      this.setWidth();
    },
    beforeDestroy() {
      delete window.actionToolbarComponent;
    },
    methods: {
      setWidth() {
        this.width = $(this.$el).parent().width();
      },
      fetchActions(params) {
        this.loading = true;
        this.debouncedFetchActions(params);
      },
      setReloadCallback(func) {
        this.reloadCallback = func;
      },
      doAction(action) {
        switch(action.type) {
          case 'legacy':
            // do nothing, this is handled by legacy code based on the button class
            break;
          case 'link':
            // do nothing, already handled by href
            break;
          case 'remote-modal':
            // do nothing, handled by the data-action="remote-modal" binding
            break;
          case 'request':
            $.ajax({
              type: action.request_method,
              url: action.path,
              data: this.params
            }).done((data) => {
              HelperModule.flashAlertMsg(data.responseJSON && data.responseJSON.message || data.message, 'success');
            }).fail((data) => {
              HelperModule.flashAlertMsg(data.responseJSON && data.responseJSON.message || data.message, 'danger');
            }).complete(() => {
              if (this.reloadCallback) this.reloadCallback();
            });
            break;
        }
      }
    }
  }
</script>
