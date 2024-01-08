<template>
  <div
    class="flex items-center mr-3 flex-nowrap relative"
    v-click-outside="closeSearchInputs"
  >
    <button :class="{hidden: searchOpened}" ref='searchInputBtn' class="btn btn-light btn-black icon-btn" data-e2e="e2e-BT-invInventoryRT-search" :title="i18n.t('repositories.show.search_button_tooltip')" @click="openSearch">
      <i class="sn-icon sn-icon-search"></i>
    </button>
    <div v-if="searchOpened || barcodeSearchOpened" class="w-52 flex">
      <div v-if="searchOpened" class="sci-input-container-v2 w-full right-icon">
        <input
          ref="searchInput"
          class="sci-input-field"
          type="text"
          :placeholder="i18n.t('repositories.show.filter_inventory_items')"
          @keyup="setValue"
        />
        <i class="sn-icon sn-icon-search !mr-2.5"></i>
      </div>
      <div v-if="barcodeSearchOpened" class="sci-input-container-v2 w-full right-icon ml-2">
        <input
          ref="barcodeSearchInput"
          class="sci-input-field"
          type="text"
          :placeholder="i18n.t('repositories.show.filter_inventory_items_with_ean')"
          @keyup="setBarcodeValue"
        />
        <i class='sn-icon sn-icon-barcode barcode-scanner !mr-2.5'></i>
      </div>
    </div>
    <button :class="{hidden: barcodeSearchOpened}" ref='barcodeSearchInputBtn' class="btn btn-light btn-black icon-btn ml-2" data-e2e="e2e-BT-invInventoryRT-barcode" :title="i18n.t('repositories.show.ean_search_button_tooltip')" @click="openBarcodeSearch">
      <i class='sn-icon sn-icon-barcode barcode-scanner'></i>
    </button>
  </div>
</template>

<script>
import { vOnClickOutside } from '@vueuse/components';

export default {
  name: 'RepositorySearchContainer',
  directives: {
    'click-outside': vOnClickOutside
  },
  data() {
    return {
      barcodeSearchOpened: false,
      barcodeValue: '',
      searchOpened: false,
      value: ''
    };
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  watch: {
    barcodeValue() {
      this.updateRepositoySearch();
    },
    value() {
      this.updateRepositoySearch();
    }
  },
  computed: {
    activeValue() {
      return this.value.length > 0 ? this.value : this.barcodeValue;
    }
  },
  methods: {
    setValue(e) {
      this.value = e.target.value;
    },
    setBarcodeValue(e) {
      this.barcodeValue = e.target.value;
    },
    openBarcodeSearch() {
      this.clearValues();
      this.searchOpened = false;
      this.barcodeSearchOpened = true;
      this.$nextTick(() => {
        this.$refs.barcodeSearchInput.focus();
      });
    },
    openSearch() {
      this.clearValues();
      this.barcodeSearchOpened = false;
      this.searchOpened = true;
      this.$nextTick(() => {
        this.$refs.searchInput.focus();
      });
    },
    closeBarcodeSearch() {
      if (this.barcodeValue.length == 0) {
        setTimeout(() => {
          this.barcodeSearchOpened = false;
        }, 100);
      }
    },
    closeSearch() {
      if (this.value.length == 0) {
        setTimeout(() => {
          this.searchOpened = false;
        }, 100);
      }
    },
    updateRepositoySearch() {
      $('.dataTables_filter input').val(this.activeValue).trigger('keyup');
    },
    clearValues() {
      this.value = '';
      this.barcodeValue = '';
      if (this.$refs.searchInput) this.$refs.searchInput.value = '';
      if (this.$refs.barcodeSearchInput) this.$refs.barcodeSearchInput.value = '';
    },
    closeSearchInputs() {
      this.closeSearch();
      this.closeBarcodeSearch();
    }
  }
};
</script>
