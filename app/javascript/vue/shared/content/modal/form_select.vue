<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" id="selectFormContent" tabindex="-1" role="dialog" data-e2e="e2e-MD-insertFormModal">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-insertFormModal-close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title" id="modal-move-result-element" data-e2e="e2e-TX-insertFormModal-title">
            <template v-if="anyForms">
              {{ i18n.t(`protocols.steps.modals.form_modal.title`) }}
            </template>
            <template v-else>
              {{ i18n.t(`protocols.steps.modals.form_modal.no_forms_title`) }}
            </template>
          </h4>
        </div>
        <div class="modal-body">
          <template v-if="anyForms">
            <p data-e2e="e2e-TX-insertFormModal-description">{{ i18n.t(`protocols.steps.modals.form_modal.description`) }}</p>
            <label class="font-normal text-sn-dark-grey" data-e2e="e2e-TX-insertFormModal-selectForm">
              {{ i18n.t(`protocols.steps.modals.form_modal.label`) }}
            </label>
            <div class="w-full">
              <SelectDropdown
                @change="setForm"
                :value="form"
                :optionsUrl="formsUrl"
                :placeholder="i18n.t(`protocols.steps.modals.form_modal.placeholder`)"
                :searchable="true"
                data-e2e="e2e-DD-insertFormModal-selectForm"
              />
            </div>

            <div v-if="recentUsedForms.length > 0" class="flex flex-col gap-2 mt-6">
              <h3 class="m-0">{{ i18n.t(`protocols.steps.modals.form_modal.recently_used`) }}</h3>
              <div>
                <div v-for="(option, i) in recentUsedForms" :key="option.id"
                  @click.stop="setForm(option.id)"
                  class="py-2.5 px-3 rounded cursor-pointer flex items-center gap-2 shrink-0 hover:bg-sn-super-light-grey"
                  :class="[{
                    '!bg-sn-super-light-blue': form === option.id
                  }]"
                >
                  <div class="truncate text-base text-sn-blue" >{{ option.name }}</div>
                </div>
              </div>
            </div>
          </template>
          <p v-else >
            {{ i18n.t(`protocols.steps.modals.form_modal.no_forms`) }}
          </p>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="close" data-e2e="e2e-BT-insertFormModal-cancel">{{ i18n.t('general.cancel') }}</button>
          <button v-if="anyForms" :disabled="!form" @click="$emit('submit', form)" class="btn btn-primary" data-e2e="e2e-BT-insertFormModal-addForm">
            {{ i18n.t('protocols.steps.modals.form_modal.add_form') }}
          </button>
          <a v-else :href="formsPageUrl" class="btn btn-primary">
            {{ i18n.t('protocols.steps.modals.form_modal.take_me_there') }}
          </a>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import modalMixin from '../../modal_mixin';
import SelectDropdown from '../../select_dropdown.vue';
import axios from '../../../../packs/custom_axios.js';

import {
  published_forms_forms_path,
  latest_attached_forms_forms_path,
  forms_path
} from '../../../../routes.js';

export default {
  name: 'formSelectModal',
  data() {
    return {
      form: null,
      anyForms: false,
      recentUsedForms: []
    };
  },
  mixins: [modalMixin],
  computed: {
    formsUrl() {
      return published_forms_forms_path();
    },
    formsPageUrl() {
      return forms_path();
    },
    formsRecentUsedUrl() {
      return latest_attached_forms_forms_path();
    }
  },
  created() {
    axios.get(this.formsUrl)
      .then((response) => {
        this.anyForms = response.data.data.length > 0;

        if (this.anyForms) {
          axios.get(this.formsRecentUsedUrl)
            .then((responseData) => {
              this.recentUsedForms = responseData.data.data;
            });
        }
      });
  },
  components: {
    SelectDropdown
  },
  methods: {
    setForm(form) {
      this.form = form;
    }
  }
};
</script>
