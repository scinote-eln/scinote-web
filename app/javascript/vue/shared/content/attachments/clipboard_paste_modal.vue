<template>
  <div ref="modal" @keydown.esc="cancel"
      @keyup.enter="uploadImage"
       class="modal clipboardPreviewModal fade"
       role="dialog" aria-hidden="true" tabindex="-1">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title">{{i18n.t('assets.from_clipboard.modal_title')}}</h4>
        </div>
        <div class="modal-body">
          <label class="sci-label">{{i18n.t('assets.from_clipboard.image_preview')}}</label>
          <div class="flex justify-center w-full">
            <canvas class="max-h-80 max-w-lg rounded border border-solid border-sn-light-grey" ref="preview" />
          </div>
          <div class="w-full py-6">
            <label class="sci-label">{{i18n.t(`assets.from_clipboard.select_${objectType}`)}}</label>
            <SelectDropdown
              :value="target"
              @change="setTarget"
              :options="targets"
              :searchable="true"
              :placeholder="
                i18n.t(`protocols.steps.modals.move_element.${objectType}.search_placeholder`)
              "
            />
          </div>
          <label class="sci-label">{{i18n.t('assets.from_clipboard.file_name')}}</label>
          <div class="sci-input-container-v2">
            <input id="clipboardImageName" type="text" class="sci-input-field !pr-16" v-model="fileName"
                    :placeholder="i18n.t('assets.from_clipboard.file_name_placeholder')" aria-describedby="image-name">
              <span class="absolute right-2.5 text-sn-grey ">
                .{{ extension }}
              </span>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="cancel">{{i18n.t('general.cancel')}}</button>
          <button type="button" class="btn btn-success" :disabled="!valid" @click="uploadImage">{{i18n.t('assets.from_clipboard.add_image')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
  import SelectDropdown from "../../select_dropdown.vue";

export default {
  name: 'clipboardPasteModal',
  props: {
    objects: Array,
    image: DataTransferItem,
    objectType: String,
    selectedObjectId: String
  },
  data() {
    return {
      target: null,
      targets: [],
      fileName: '',
      extension: ''
    };
  },
  components: {
    SelectDropdown
  },
  computed: {
    valid() {
      return this.target && this.fileName.length > 0;
    }
  },
  mounted() {
    $(this.$refs.modal).modal('show');
    this.appendImage(this.image);
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('cancel');
    });

    if (this.selectedObjectId) this.target = this.selectedObjectId;
    this.targets = this.objects.map((object) => [
      object.id,
      object.attributes.name
    ]);
  },
  methods: {
    setTarget(target) {
      this.target = target;
    },
    cancel() {
      $(this.$refs.modal).modal('hide');
    },
    appendImage(item) {
      const imageBlob = item.getAsFile();
      if (imageBlob) {
        const canvas = this.$refs.preview;
        const ctx = canvas.getContext('2d');
        const img = new Image();
        img.onload = function () {
          canvas.width = this.width;
          canvas.height = this.height;
          ctx.drawImage(img, 0, 0);
        };
        const URLObj = window.URL || window.webkitURL;
        img.src = URLObj.createObjectURL(imageBlob);
        const extension = imageBlob.name.slice(
          (Math.max(0, imageBlob.name.lastIndexOf('.')) || Infinity) + 1
        );
        this.extension = extension;
        this.imageBlob = imageBlob;
      }
    }
  }
};
</script>
