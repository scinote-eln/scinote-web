<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" id="modalDestroyProtocolContent" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title" id="modal-destroy-team-label">
            {{ i18n.t(`protocols.steps.modals.move_element.${parent_type}.title`) }}
          </h4>
        </div>
        <div class="modal-body">
          <label>
            {{ i18n.t(`protocols.steps.modals.move_element.${parent_type}.targets_label`) }}
          </label>
          <div class="w-full">
            <Select
              :value="target"
              :options="getOptions(targets)"
              v-bind:disabled="false"
              @change="setTarget"
            ></Select>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancel">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="confirm">{{ i18n.t('general.save')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>
 <script>
  import axios from '../../../../packs/custom_axios.js';
  import Select from "../../select.vue";

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
    data () {
      return {
        target: null,
        targets: []
      }
    },
    components: {
      Select
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
          .then(response => {
            this.targets = response.data.targets;
          })
      },
      confirm() {
        $(this.$refs.modal).modal('hide');
        this.$emit('confirm', this.target);
      },
      cancel() {
        $(this.$refs.modal).modal('hide');
      },
      getOptions(targets) {
        const updatedTargets = targets.map(target => {
          if (target[1] === null) {
            target[2] = this.i18n.t('protocols.steps.modals.move_element.result.untitled_result');
          }
          return target;
        });

        return updatedTargets;
      }
    }
  }
</script>
