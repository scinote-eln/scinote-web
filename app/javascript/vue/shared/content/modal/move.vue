<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" id="modalMoveProtocolContent" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title" id="modal-move-result-element">
            {{ i18n.t(`protocols.steps.modals.move_element.${parent_type}.title`) }}
          </h4>
        </div>
        <div class="modal-body">
          <label class="font-normal text-sn-dark-grey">
            {{ i18n.t(`protocols.steps.modals.move_element.${parent_type}.targets_label`) }}
          </label>
          <div class="w-full">
            <SelectDropdown
              :value="target"
              @change="setTarget"
              :options="targetOptions"
              :searchable="true"
              :placeholder="
                i18n.t(`protocols.steps.modals.move_element.${parent_type}.search_placeholder`)
              "
              :no-options-placeholder="
                i18n.t(
                  `my_modules.results.move_modal.${parent_type}.no_options_placeholder`
                )
              "
            />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancel">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="confirm" :disabled="!target">{{ i18n.t('general.move')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>
 <script>
import axios from '../../../../packs/custom_axios.js';
import SelectDropdown from "../../select_dropdown.vue";

export default {
  name: 'moveElementModal',
  props: {
    parent_type: {
      type: String,
      required: true
    },
    targets_url: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      target: null,
      targets: []
    };
  },
  components: {
    SelectDropdown
  },
  mounted() {
    $(this.$refs.modal).modal('show');
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('cancel');
    });
    this.fetchTargets();
  },
  methods: {
    setTarget(target) {
      this.target = target;
    },
    fetchTargets() {
      axios.get(this.targets_url)
        .then((response) => {
          this.targets = response.data.targets;
        });
    },
    confirm() {
      $(this.$refs.modal).modal('hide');
      this.$emit('confirm', this.target);
    },
    cancel() {
      $(this.$refs.modal).modal('hide');
    }
  },
  computed: {
    targetOptions() {
      return this.targets.map((target) => [
        target[0],
        target[1] || this.i18n.t('protocols.steps.modals.move_element.result.untitled_result'),
        target[1] === null
      ]);
    }
  }
};
</script>
