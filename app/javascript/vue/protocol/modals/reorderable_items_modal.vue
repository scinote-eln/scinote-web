<template>
  <div ref="modal" @keydown.esc="close" class="modal sci-reorderable-items" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button @click="close" type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
          <h4 class="modal-title">
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
          >
            <div v-for="(item, index) in reorderedItems" :key="item.id" class="step-element-header">
              <div class="step-element-grip step-element-grip--draggable">
                <i class="fas fa-grip-vertical"></i>
              </div>
              <div class="step-element-name">
                <strong v-if="includeNumbers" class="step-element-number">{{ index + 1 }}</strong>
                <i v-if="item.attributes.icon" class="fas" :class="item.attributes.icon"></i>
                <span :title="nameWithFallbacks(item)" v-if="nameWithFallbacks(item)">{{ nameWithFallbacks(item) }}</span>
                <span :title="item.attributes.placeholder" v-else class="step-element-name-placeholder">{{ item.attributes.placeholder }}</span>
              </div>
            </div>
          </Draggable>
        </div>
      </div>
    </div>
  </div>
</template>
 <script>
  import Draggable from 'vuedraggable'

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
        required: true,
      },
      includeNumbers: {
        type: Boolean,
        default: false
      }
    },
    data() {
      return {
        reorderedItems: [...this.items]
      }
    },
    mounted() {
      $(this.$refs.modal).modal('show');
      $(this.$refs.modal).on('hidden.bs.modal', () => {
        this.close();
      })
    },
    methods: {
      close() {
        this.$emit('reorder', this.reorderedItems);
      },
      getTitle(item) {
        let $item_html = $(item.attributes.text);
        $item_html.remove('table, img');
        let str = $item_html.text().trim();
        return str.length > 56 ? str.slice(0, 56) + "..." : str;
      },
      nameWithFallbacks(item) {
        return this.getTitle(item) || item.attributes.name;
      }
    }
  }
</script>
