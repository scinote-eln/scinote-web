<template>
  <div v-if="!paramsAreBlank"
       class="sn-action-toolbar p-4 w-full fixed bottom-0 rounded-t-md"
       :class="{ 'sn-action-toolbar--button-overflow': buttonOverflow }"
       :style="`width: ${width}px; bottom: ${bottomOffset}px; transform: translateX(${leftOffset}px)`"
       :data-e2e="`e2e-CO-actionToolbar`">
    <div class="sn-action-toolbar__actions flex gap-4">
      <div v-if="loading && !actions.length" class="sn-action-toolbar__action">
        <a class="rounded flex items-center py-1.5 px-2.5 bg-transparent text-transparent no-underline"></a>
      </div>
      <div v-if="!loading && actions.length === 0" class="sn-action-toolbar__message">
        {{ i18n.t('action_toolbar.no_actions') }}
      </div>
      <div v-for="action in actions" :key="action.name" class="sn-action-toolbar__action shrink-0">
          <div v-if="action.type === 'group' && Array.isArray(action.actions) && action.actions.length > 1" class="export-actions-dropdown sci-dropdown dropup">
            <button class="btn btn-primary dropdown-toggle single-object-action rounded" type="button" id="exportDropdown" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true" data-e2e="e2e-DD-actionToolbar-export">
              <i class="sn-icon sn-icon-export"></i>
              <span class="sn-action-toolbar__button-text">{{ action.group_label }}</span>
              <span class="sn-icon sn-icon-down"></span>
            </button>
            <ul class="sci-dropdown dropup dropdown-menu dropdown-menu-right px-2" aria-labelledby="<%= id %>">
              <li v-for="groupAction in action.actions" class="">
                <a :class="`flex gap-2 items-center bg-sn-white color-sn-blue no-underline ${groupAction.button_class}`"
                  :href="(['link', 'remote-modal']).includes(groupAction.type) ? groupAction.path : '#'"
                  :id="groupAction.button_id"
                  :title="groupAction.label"
                  :data-url="groupAction.path"
                  :data-target="groupAction.target"
                  :data-toggle="groupAction.type === 'modal' && 'modal'"
                  :data-object-type="groupAction.item_type"
                  :data-object-id="groupAction.item_id"
                  :data-action="groupAction.type"
                  @click="closeExportDropdown($event); doAction(groupAction, $event);">
                  <span>{{ groupAction.label }}</span>
                </a>
              </li>
            </ul>
          </div>
          <a :class="`rounded flex gap-2 items-center py-1.5 px-2.5 bg-sn-white color-sn-blue no-underline ${action.actions[0].button_class}`"
            v-else-if="action.type === 'group' && Array.isArray(action.actions) && action.actions.length == 1"
            :href="(['link', 'remote-modal']).includes(action.actions[0].type) ? action.actions[0].path : '#'"
            :id="action.actions[0].button_id"
            :title="action.group_label"
            :data-url="action.actions[0].path"
            :data-target="action.actions[0].target"
            :data-toggle="action.actions[0].type === 'modal' && 'modal'"
            :data-object-type="action.actions[0].item_type"
            :data-object-id="action.actions[0].item_id"
            :data-action="action.actions[0].type"
            :data-e2e="`e2e-BT-actionToolbar-${action.name === 'export_group' ? 'export' : action.name}`"
            @click="doAction(action.actions[0], $event);">
            <i :class="action.actions[0].icon"></i>
            <span class="sn-action-toolbar__button-text">{{ action.group_label }}</span>
          </a>
          <a :class="`rounded flex gap-2 items-center py-1.5 px-2.5 bg-sn-white color-sn-blue no-underline ${action.button_class}`"
            :href="(['link', 'remote-modal']).includes(action.type) ? action.path : '#'"
            :id="action.button_id"
            :title="action.label"
            :data-url="action.path"
            :data-target="action.target"
            v-else
            :data-toggle="action.type === 'modal' && 'modal'"
            :data-object-type="action.item_type"
            :data-object-id="action.item_id"
            :data-action="action.type"
            :data-e2e="`e2e-BT-actionToolbar-${action.name === 'export_group' ? 'export' : action.name}`"
            @click="doAction(action, $event)">
            <i :class="action.icon"></i>
            <span class="sn-action-toolbar__button-text">{{ action.label }}</span>
          </a>
        </div>
      </div>
  </div>
</template>

<script>
import { debounce } from '../shared/debounce.js';

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
      actionsLoadedCallback: null,
      loaded: false,
      loading: false,
      width: 0,
      bottomOffset: 0,
      leftOffset: 0,
      buttonOverflow: false
    };
  },
  created() {
    window.actionToolbarComponent = this;
    window.onresize = this.setWidth;

    this.debouncedFetchActions = debounce((params) => {
      this.params = params;

      $.get(`${this.actionsUrl}?${new URLSearchParams(this.params).toString()}`, (data) => {
        this.actions = data.actions;
        this.loading = false;
        this.setButtonOverflow();
        if (this.actionsLoadedCallback) this.$nextTick(this.actionsLoadedCallback);
      });
    }, 10);
  },
  mounted() {
    this.$nextTick(this.setWidth);
    window.addEventListener('scroll', this.setLeftOffset);
  },
  beforeUnmount() {
    delete window.actionToolbarComponent;
    window.removeEventListener('scroll', this.setLeftOffset);
  },
  computed: {
    paramsAreBlank() {
      const values = Object.values(this.params);

      if (values.length === 0) return true;

      return !values.some((v) => v.length);
    }
  },
  methods: {
    setWidth() {
      this.width = $(this.$el).parent().width();
      this.setButtonOverflow();
    },
    setButtonOverflow() {
      // detects if the last action button is outside the toolbar container
      this.buttonOverflow = false;

      this.$nextTick(() => {
        if (
          !(this.$el.getBoundingClientRect
                && document.querySelector('.sn-action-toolbar__action:last-child'))
        ) return;

        const containerRect = this.$el.getBoundingClientRect();
        const lastActionRect = document.querySelector('.sn-action-toolbar__action:last-child').getBoundingClientRect();

        this.buttonOverflow = containerRect.left + containerRect.width < lastActionRect.left + lastActionRect.width;
      });
    },
    setLeftOffset() {
      this.leftOffset = -(window.pageXOffset || document.documentElement.scrollLeft);
    },
    setBottomOffset(pixels) {
      this.bottomOffset = pixels;
    },
    fetchActions(params) {
      this.loading = true;
      this.debouncedFetchActions(params);
    },
    setReloadCallback(func) {
      this.reloadCallback = func;
    },
    setActionsLoadedCallback(func) {
      this.actionsLoadedCallback = func;
    },
    doAction(action, event) {
      switch (action.type) {
        case 'legacy':
          // do nothing, this is handled by legacy code based on the button class
          break;
        case 'link':
          // do nothing, already handled by href
          break;
        case 'modal':
          // do nothihg, boostrap modal handled by data-toggle="modal" and data-target
        case 'remote-modal':
          // do nothing, handled by the data-action="remote-modal" binding
          break;
        case 'download':
          event.stopPropagation();
          window.location.href = action.path;
          break;
        case 'request':
          event.stopPropagation();
          $.ajax({
            type: action.request_method,
            url: action.path,
            data: this.params
          }).done((data) => {
            HelperModule.flashAlertMsg(data.responseJSON && data.responseJSON.message || data.message, 'success');
          }).fail((data) => {
            HelperModule.flashAlertMsg(data.responseJSON && data.responseJSON.message || data.message, 'danger');
          }).always(() => {
            if (this.reloadCallback) this.reloadCallback();
          });
          break;
      }
    },
    closeExportDropdown(event) {
      event.preventDefault();
      $(event.target).closest('.export-actions-dropdown').removeClass('open');
    }
  }
};
</script>
