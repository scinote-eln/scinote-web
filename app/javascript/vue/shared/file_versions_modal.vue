<template>
  <div ref="modal" @keydown.esc="close" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button @click="close" type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t("assets.file_versions_modal.title") }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="relative" v-if="fileVersions">
            <div v-for="(fileVersion, index) in fileVersions" :key="fileVersion.id">
              <div class="flex w-full border border-sn-light-grey rounded mb-1.5 p-1.5 items-center">
                <div class="basis-full">
                  <div class="mb-1.5">
                    <span v-if="fileVersion.attributes.version === 1" class="bg-sn-science-blue text-sn-white me-2 px-2 py-0.5 rounded">
                      {{ i18n.t("assets.file_versions_modal.original_file") }}
                    </span>
                    <span v-else class="bg-sn-grey-300 me-2 px-2 py-0.5 rounded">v{{ fileVersion.attributes.version }}</span>
                    <a :href="fileVersion.attributes.url" target="_blank" class="align-text-bottom">
                      <span :class="{
                          'max-w-80': !fileVersion.attributes.restored_from_version && fileVersion.attributes.version !== 1,
                          'max-w-64': !!fileVersion.attributes.restored_from_version || fileVersion.attributes.version === 1
                        }"
                        class="text-ellipsis overflow-hidden text-nowrap inline-block align-middle"
                      >{{ fileVersion.attributes.basename }}.</span><span class="inline-block align-middle">{{ fileVersion.attributes.extension }}</span>
                    </a>
                    <small class="inline-block ml-1" v-if="fileVersion.attributes.restored_from_version">
                      ({{ i18n.t("assets.file_versions_modal.restored_from_version", { version: fileVersion.attributes.restored_from_version }) }})
                    </small>
                  </div>
                  <div class="flex text-xs text-sn-grey justify-start">
                    <div class="mr-3">{{ fileVersion.attributes.created_at }}</div>
                    <div class="mr-3 text-nowrap text-ellipsis overflow-hidden max-w-52">{{ fileVersion.attributes.created_by.full_name }}</div>
                    <div>{{ Math.round(fileVersion.attributes.byte_size/1024) }}KB</div>
                  </div>
                </div>

                <div class="basis-1/4 flex justify-end">
                  <a class="btn btn-icon p-0 px-2 hover:bg-sn-light-grey"
                    v-if="enabled || index === 0"
                    :href="fileVersion.attributes.url"
                    target="_blank"
                    data-render-tooltip="true"
                    :title="i18n.t('assets.file_versions_modal.download')"
                  >
                    <i class="sn-icon sn-icon-export"></i>
                  </a>
                  <a v-if="restoreVersionUrl && index !== 0"
                    @click="restoreVersion(fileVersion.attributes.version)"
                    data-render-tooltip="true"
                    :title="i18n.t('assets.file_versions_modal.restore')"
                    class="btn btn-icon p-0 px-2 hover:bg-sn-light-grey"
                  >
                    <i class="sn-icon sn-icon-restore"></i>
                  </a>
                </div>
              </div>
            </div>
            <div v-if="!enabled" class="absolute bottom-0 w-full h-[150px] bg-gradient-to-t from-white to-transparent"></div>
          </div>
          <div v-else class="sci-loader"></div>
          <div v-if="fileVersions && !enabled" class="bg-sn-super-light-blue p-4 rounded flex items-start">
            <div class="mr-2">
              <i class="sn-icon sn-icon-upgrade"></i>
            </div>
            <div>
              <h3 class="mt-1 mb-2">{{ i18n.t('assets.file_versions_modal.title') }}</h3>
              {{ i18n.t('assets.file_versions_modal.disabled_disclaimer') }}
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type='button' class='btn btn-secondary' @click="close">
            {{ i18n.t('general.cancel') }}
          </button>
          <a v-if="fileVersions && !enabled" :href="enableUrl" class='btn btn-primary' target="_blank">
            {{ i18n.t('assets.file_versions_modal.enable_button') }}
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from './modal_mixin';
import axios from '../../packs/custom_axios';

export default {
  name: 'FileVersionsModal',
  props: {
    versionsUrl: {
      type: String,
      required: true
    },
    restoreVersionUrl: {
      type: String,
      required: true
    }
  },
  mixins: [modalMixin],
  data() {
    return {
      fileVersions: null,
      enabled: null,
      enableUrl: null
    };
  },
  created() {
    this.loadVersions();
  },
  beforeUnmount() {
    document.querySelectorAll('[data-render-tooltip]').forEach((e) => {
      window.destroyTooltip(e);
    });
  },
  methods: {
    loadVersions() {
      axios.get(this.versionsUrl).then((response) => {
        this.fileVersions = response.data.data;
        this.enabled = response.data.enabled;
        this.enableUrl = response.data.enable_url;
        this.$nextTick(() => {
          document.querySelectorAll('[data-render-tooltip]').forEach((e) => {
            window.initTooltip(e);
          });
        });
      });
    },
    restoreVersion(version) {
      axios.post(this.restoreVersionUrl, { version: version }).then(() => {
        this.loadVersions();
        this.$emit('fileVersionRestored');
      });
    }
  }
};
</script>
