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
            @end="reorder"
          >
            <div v-for="item in reorderedItems" :key="item.id" class="step-element-header">
              <div class="step-element-grip">
                <i class="fas fa-grip-vertical"></i>
              </div>
              <div class="step-element-name">
                <i class="fas" :class="item.icon"></i>
                {{ item.description }}
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
      }
    },
    data() {
      return {
        reorderedItems: [...this.items]
      }
    },
    mounted() {
      $(this.$refs.modal).modal('show');
    },
    methods: {
      close() {
        $(this.$refs.modal).modal('hide');
        this.$emit('close');
      },
      reorder() {
        this.$emit('reorder', this.reorderedItems);
      }
    }
  }
</script>
