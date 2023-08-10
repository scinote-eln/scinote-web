<template>
  <div class="result-wrapper">
    {{ result.id }}
    {{ result.attributes.name }}
    <button @click="openReorderModal">
      Open Rearrange Modal
    </button>
    <a href="#"
       ref="comments"
       class="open-comments-sidebar btn icon-btn btn-light btn-black"
       data-turbolinks="false"
       data-object-type="Result"
       :data-object-id="result.id">
       <i class="sn-icon sn-icon-comments"></i>
    </a>
    <hr>
    <ReorderableItemsModal v-if="reordering"
      title="Placeholder title for this modal"
      :items="reorderableElements"
      @reorder="updateElementOrder"
      @close="closeReorderModal"
    />
  </div>
</template>

<script>
  import axios from 'axios';
  import ReorderableItemsModal from '../shared/reorderable_items_modal.vue'

  export default {
    name: 'Results',
    props: {
      result: { type: Object, required: true }
    },
    data() {
      return {
        reordering: false,
        elements: []
      }
    },
    components: {
      ReorderableItemsModal
    },
    computed: {
      reorderableElements() {
        return this.orderedElements.map((e) => { return { id: e.id, attributes: e.attributes.orderable } })
      },
      orderedElements() {
        return this.elements.sort((a, b) => a.attributes.position - b.attributes.position);
      },
      urls() {
        return this.result.attributes.urls || {}
      }
    },
    methods: {
      openReorderModal() {
        this.reordering = true;
      },
      closeReorderModal() {
        this.reordering = false;
      },
      updateElementOrder(orderedElements) {
        orderedElements.forEach((element, position) => {
          let index = this.elements.findIndex((e) => e.id === element.id);
          this.elements[index].attributes.position = position;
        });

        let elementPositions = {
          result_orderable_element_positions: this.elements.map(
            (element) => [element.id, element.attributes.position]
          )
        };

        axios.post(this.urls.reorder_elements_url, elementPositions, {
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }
        })
        .then(() => {
          this.$emit('stepUpdated');
        })
        .catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        });
      },
    }
  }
</script>
