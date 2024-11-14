<template>
  <div ref="modal" @keydown.esc="close" class="modal sci-reorderable-items" tabindex="-1" role="dialog" :data-e2e="`e2e-MD-${dataE2e}`">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button @click="close" type="button" class="close" data-dismiss="modal" aria-label="Close" :data-e2e="`e2e-BT-${dataE2e}-close`">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title" :data-e2e="`e2e-TX-${dataE2e}-title`">
            {{ title }}
          </h4>
        </div>
        <div class="modal-body">
          <Draggable
            v-model="reorderedItems"
            :ghostClass="'step-checklist-item-ghost'"
            :dragClass="'step-checklist-item-drag'"
            :chosenClass="'step-checklist-item-chosen'"
            :handle="'.step-element-grip'"
            item-key="id"
          >
            <template #item="{element, index}">
              <div class="step-element-header flex items-center">
                <div class="step-element-grip step-element-grip--draggable">
                  <i class="sn-icon sn-icon-drag" :data-e2e="`e2e-BT-${dataE2e}-element${index + 1}-drag`"></i>
                </div>
                <div class="step-element-name text-center flex items-center gap-2">
                  <strong v-if="includeNumbers" class="step-element-number" :data-e2e="`e2e-TX-${dataE2e}-element${index + 1}-position`">
                    {{ index + 1 }}
                  </strong>
                  <i v-if="element.attributes.icon" class="fas" :class="element.attributes.icon" :data-e2e="`e2e-IC-${dataE2e}-element${index + 1}`"></i>
                  <span
                    :title="nameWithFallbacks(element)"
                    v-if="nameWithFallbacks(element)"
                    :data-e2e="`e2e-TX-${dataE2e}-element${index + 1}-name`"
                  >
                    {{ nameWithFallbacks(element) }}
                  </span>
                  <span :title="element.attributes.placeholder" v-else class="step-element-name-placeholder" :data-e2e="`e2e-TX-${dataE2e}-element${index + 1}-name`">
                    {{ element.attributes.placeholder }}
                  </span>
                </div>
              </div>
            </template>
          </Draggable>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import Draggable from 'vuedraggable';

export default {
  name: 'ReorderableItems',
  components: {
    Draggable
  },
  props: {
    title: {
      type: String,
      required: true
    },
    items: {
      type: Array,
      required: true
    },
    includeNumbers: {
      type: Boolean,
      default: false
    },
    dataE2e: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      reorderedItems: [...this.items]
    };
  },
  mounted() {
    window.$(this.$refs.modal).modal('show');
    window.$(this.$refs.modal).on('hidden.bs.modal', () => {
      this.close();
    });
  },
  methods: {
    close() {
      this.$emit('reorder', this.reorderedItems);
      this.$emit('close');
    },
    getTitle(item) {
      const $item_html = $(item.attributes.text);
      $item_html.remove('table, img');
      const str = $item_html.text().trim();
      return str.length > 56 ? `${str.slice(0, 56)}...` : str;
    },
    nameWithFallbacks(item) {
      return this.getTitle(item) || item.attributes.name;
    }
  }
};
</script>
