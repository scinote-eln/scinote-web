<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog" data-backdrop="static" data-keyboard="false">
    <div class="modal-dialog" role="document" :class="[{'!w-[900px]' : showingInfo}, {'!w-fit' : !showingInfo}]">
      <div class="modal-content !p-0 bg-sn-white w-full h-full flex" :class="[{'flex-row': showingInfo}, {'flex-col': !showingInfo}]">
        <div id="body-container" class="flex flex-row w-full h-full">
          <!-- info -->
          <div id="info-part" ref="infoPartRef">
            <InfoComponent
              v-if="showingInfo"
              :infoParams="infoParams"
            />
          </div>
          <!-- content -->
          <div id="content-part" class="flex flex-col w-full p-6 gap-6">
            <!-- header -->
            <div id="info-modal-header" class="flex flex-col h-fit w-full gap-2">
              <div id="title-part" class="flex flex-row h-fit w-full justify-between">
                <div id="title-with-help" class="flex flex-row gap-3">
                  <h3 class="modal-title text-sn-dark-grey">{{ title }}</h3>
                  <button v-if="helpText" class="btn btn-light btn-sm" @click="showingInfo = !showingInfo">
                    <i class="sn-icon sn-icon-help-s"></i>
                    {{ helpText }}
                  </button>
                </div>
                <button id="close-btn" type="button" class="close my-auto" data-dismiss="modal" aria-label="Close">
                  <i class="sn-icon sn-icon-close"></i>
                </button>
              </div>
              <div id="subtitle-part" class="text-sn-dark-grey">
                {{ subtitle }}
              </div>
            </div>
            <!-- main content -->
            <div id="info-modal-main-content" class="h-full">
              <slot></slot>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from './modal_mixin';
import InfoComponent from './info_component.vue';

export default {
  name: 'InfoModal',
  props: {
    title: {
      type: String,
      required: true
    },
    subtitle: {
      type: String,
      required: false
    },
    helpText: {
      type: String,
      required: false
    },
    infoParams: {
      type: Object,
      required: true
    },
    startHidden: {
      type: Boolean,
      default: false
    }
  },
  mixins: [modalMixin],
  components: { InfoComponent },
  data() {
    return {
      showingInfo: false
    };
  }
};
</script>
