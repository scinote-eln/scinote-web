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
          <p><strong>{{i18n.t('assets.from_clipboard.image_preview')}}</strong></p>
          <canvas style="border:1px solid grey;max-width:400px;max-height:300px" id="clipboardPreview" />
          <p><strong>{{i18n.t('assets.from_clipboard.file_name')}}</strong></p>
          <div class="input-group">
            <input id="clipboardImageName" type="text" class="form-control"
                    :placeholder="i18n.t('assets.from_clipboard.file_name_placeholder')" aria-describedby="image-name">
              <span class="input-group-addon" id="image-name"></span>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="cancel">{{i18n.t('general.cancel')}}</button>
          <button type="button" class="btn btn-success" @click="uploadImage">{{i18n.t('assets.from_clipboard.add_image')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
  export default {
    name: 'clipboardPasteModal',
    props: {
      parent: Object,
      image: DataTransferItem
    },
    mounted() {
      $(this.$refs.modal).modal('show');
      this.appendImage(this.image);
      $(this.$refs.modal).on('hidden.bs.modal', () => {
        this.$emit('cancel');
      });
    },
    methods: {
      cancel() {
        $(this.$refs.modal).modal('hide');
      },
      appendImage(item) {
        let imageBlob = item.getAsFile();
        if (imageBlob) {
          var canvas = document.getElementById('clipboardPreview');
          var ctx = canvas.getContext('2d');
          var img = new Image();
          img.onload = function() {
            canvas.width = this.width;
            canvas.height = this.height;
            ctx.drawImage(img, 0, 0);
          };
          let URLObj = window.URL || window.webkitURL;
          img.src = URLObj.createObjectURL(imageBlob);
          let extension = imageBlob.name.slice(
            (Math.max(0, imageBlob.name.lastIndexOf('.')) || Infinity) + 1
          );
          $('#image-name').html('.' + extension); // add extension near file name
          this.imageBlob = imageBlob;
        }
      },
      uploadImage() {
        let newName = $('#clipboardImageName').val();
        let imageBlog = this.imageBlob;
        // check if the name is set
        if (newName && newName.length > 0) {
          let extension = imageBlog.name.slice(
            (Math.max(0, imageBlog.name.lastIndexOf('.')) || Infinity) + 1
          );
          // hack to inject custom name in File object
          let name = newName + '.' + extension;
          let blob = imageBlog.slice(0, imageBlog.size, imageBlog.type);
          // make new blob with the correct name;
          this.imageBlob = new File([blob], name, { type: imageBlog.type });
        }
        $(this.$refs.modal).modal('hide');
        this.$emit('files', this.imageBlob);
      }
    }
  }
</script>
