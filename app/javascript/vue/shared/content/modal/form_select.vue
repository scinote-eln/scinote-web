<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" id="selectFormContent" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title" id="modal-move-result-element">
            {{ i18n.t(`protocols.steps.modals.form_modal.title`) }}
          </h4>
        </div>
        <div class="modal-body">
          <template v-if="anyForms">
            <p>{{ i18n.t(`protocols.steps.modals.form_modal.description`) }}</p>
            <label class="font-normal text-sn-dark-grey">
              {{ i18n.t(`protocols.steps.modals.form_modal.label`) }}
            </label>
            <div class="w-full">
              <SelectDropdown
                @change="setForm"
                :optionsUrl="formsUrl"
                :placeholder="i18n.t(`protocols.steps.modals.form_modal.placeholder`)"
                :searchable="true"
              />
            </div>
          </template>
          <p v-else>
            {{ i18n.t(`protocols.steps.modals.form_modal.no_forms`) }}
          </p>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="close">{{ i18n.t('general.cancel') }}</button>
          <button v-if="anyForms" :disabled="!form" @submit="$emit('submit', form)" class="btn btn-primary">
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
  forms_path
} from '../../../../routes.js';

export default {
  name: 'formSelectModal',
  data() {
    return {
      form: null,
      anyForms: false
    };
  },
  mixins: [modalMixin],
  computed: {
    formsUrl() {
      return published_forms_forms_path();
    },
    formsPageUrl() {
      return forms_path();
    }
  },
  created() {
    axios.get(this.formsUrl)
      .then((response) => {
        this.anyForms = response.data.data.length > 0;
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
