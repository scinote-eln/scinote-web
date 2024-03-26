<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content ">
        <div class="modal-header">
          <button type="button" class="close self-start" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title line-clamp-3" style="display: -webkit-box;">
            {{ i18n.t('protocols.index.linked_children.title', { protocol: protocol.name }) }}
          </h4>
        </div>
        <div class="modal-body gap-6">
          <div class="flex items-center gap-4 mb-6">
            {{ i18n.t("protocols.index.linked_children.show_version") }}
            <div class="w-48 mr-auto">
              <SelectDropdown
                :options="versionsList"
                :value="selectedVersion"
                @change="changeSelectedVersion"
              ></SelectDropdown>
            </div>
          </div>
          <hr />
          <perfect-scrollbar
            class="max-h-96 relative flex flex-col gap-6 pr-8"
            @ps-scroll-y="onScroll" ref="linkedMyModules">
            <div v-for="(myModule, idx) in linkedMyModules" class="flex items-center gap-1 flex-wrap w-full">
              <div v-if="myModule.project_folder_name" class="flex items-center ">
                <a :href="myModule.project_folder_url"
                    :title="myModule.project_folder_name"
                    class="hover:no-underline flex items-center shrink-0 gap-1 ">
                  <i class="sn-icon sn-icon-mini-folder-left"></i>
                  <span class="truncate max-w-[200px]">{{ myModule.project_folder_name }}</span>
                </a>
                <i class="sn-icon sn-icon-right"></i>
              </div>
              <div class="flex items-center">
                <a :href="myModule.project_url"
                    :title="myModule.project_name"
                    class="hover:no-underline flex items-center shrink-0 gap-1">
                  <i class="sn-icon sn-icon-projects"></i>
                  <span class="truncate max-w-[200px]">{{ myModule.project_name }}</span>
                </a>
                <i class="sn-icon sn-icon-right"></i>
              </div>
              <div class="flex items-center">
                <a :href="myModule.experiment_url"
                    :title="myModule.experiment_name"
                    class="hover:no-underline flex items-center shrink-0 gap-1">
                  <i class="sn-icon sn-icon-experiment"></i>
                  <span class="truncate max-w-[200px]">{{ myModule.experiment_name }}</span>
                </a>
                <i class="sn-icon sn-icon-right"></i>
              </div>
              <div class="flex items-center">
                <a :href="myModule.my_module_url"
                    :title="myModule.my_module_name"
                    class="hover:no-underline flex items-center shrink-0 gap-1 ">
                  <i class="sn-icon sn-icon-task"></i>
                  <span class="truncate max-w-[200px]">{{ myModule.my_module_name }}</span>
                </a>
              </div>

              <div v-if="idx !== linkedMyModules.length - 1" class="sci-divider mt-6"></div>
            </div>
          </perfect-scrollbar>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import SelectDropdown from '../../shared/select_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import Pagination from '../../shared/datatable/pagination.vue';

export default {
  name: 'NewProtocolModal',
  props: {
    protocol: Object
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown,
    Pagination
  },
  data() {
    return {
      linkedMyModules: [],
      versionsList: [],
      selectedVersion: 'All',
      nextPage: null
    };
  },
  mounted() {
    this.loadLinkedMyModules();
    this.loadVersions();
  },
  methods: {
    loadLinkedMyModules(myModules = []) {
      const urlParams = { page: this.nextPage || 1 };
      if (this.selectedVersion !== 'All') {
        urlParams.version = this.selectedVersion;
      }
      axios.get(this.protocol.urls.linked_my_modules, { params: urlParams })
        .then((response) => {
          this.linkedMyModules = myModules.concat(response.data.data);
          this.nextPage = response.data.next_page;
        });
    },
    loadVersions() {
      axios.get(this.protocol.urls.versions_list)
        .then((response) => {
          this.versionsList = [['All', 'All']].concat(response.data.versions.map((version) => [version, version]));
        });
    },
    changeSelectedVersion(version) {
      this.selectedVersion = version;
      this.nextPage = null;
      this.loadLinkedMyModules();
    },
    onScroll() {
      const scrollObj = this.$refs.linkedMyModules.ps;

      if (scrollObj) {
        const reachedEnd = scrollObj.reach.y === 'end';
        if (reachedEnd && this.contentHeight !== scrollObj.contentHeight) {
          this.contentHeight = scrollObj.contentHeight;
          if (this.nextPage) this.loadLinkedMyModules(this.linkedMyModules);
        }
      }
    }
  }
};
</script>
