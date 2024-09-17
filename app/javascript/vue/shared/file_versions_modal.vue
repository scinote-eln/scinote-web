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
          <div v-if="fileVersions" v-for="fileVersion in fileVersions" :key="fileVersion.id">
            <div class="flex w-full border border-sn-light-grey rounded mb-1.5 p-1.5 items-center">
              <div class="basis-3/4">
                <div class="mb-1.5">
                  <span class="bg-sn-grey-300 me-2 px-2 py-0.5 rounded">v{{ fileVersion.attributes.version }}</span>
                  <a :href="fileVersion.attributes.url" target="_blank">{{ fileVersion.attributes.filename }}</a>
                  <small class="inline-block" v-if="fileVersion.attributes.restored_from_version">
                    ({{ i18n.t("assets.file_versions_modal.restored_from_version", { version: fileVersion.attributes.restored_from_version }) }})
                  </small>
                </div>
                <div class="flex text-xs text-sn-grey justify-start">
                  <div class="mr-3">{{ fileVersion.attributes.created_at }}</div>
                  <div class="mr-3">{{ fileVersion.attributes.created_by.full_name }}</div>
                  <div>{{ (fileVersion.attributes.byte_size/1024).toFixed(1) }}KB</div>
                </div>
              </div>

              <div class="basis-1/4 flex justify-end">
                <a class="btn btn-icon p-0" :href="fileVersion.attributes.url" target="_blank"><i class="sn-icon sn-icon-export"></i></a>
                <a class="btn btn-icon p-0 mx-3"><i class="sn-icon sn-icon-restore"></i></a>
              </div>
            </div>
          </div>
          <div v-else class="sci-loader"></div>
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
    url: {
      type: String,
      required: true
    }
  },
  mixins: [modalMixin],
  data() {
    return {
      fileVersions: null
    };
  },
  created() {
    axios.get(this.url).then((response) => {
      this.fileVersions = response.data.data;
    });
  }
};
</script>
