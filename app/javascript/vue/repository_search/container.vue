<template>
  <div class="flex items-center mr-3 flex-nowrap">
    <button v-if="!searchOpened" class="btn btn-light icon-btn" @click="openSearch">
      <i class="fas fa-search"></i>
    </button>
    <div v-if="searchOpened || barcodeSearchOpened" class="w-52 flex">
      <div v-if="searchOpened" class="sci-input-container right-icon">
        <input
          ref="searchInput"
          class="sci-input-field"
          type="text"
          :placeholder="i18n.t('repositories.show.filter_inventory_items')"
          @keyup="setValue"
          @blur="closeSearch"
        />
        <i class="fas fa-search"></i>
      </div>
      <div v-if="barcodeSearchOpened" class="sci-input-container right-icon ml-2">
        <input
          ref="barcodeSearchInput"
          class="sci-input-field"
          type="text"
          :placeholder="i18n.t('repositories.show.filter_inventory_items_with_ean')"
          @change="setBarcodeValue"
          @blur="closeBarcodeSearch"
        />
        <img class="barcode-scanner" src="/images/icon_small/barcode.png"/>
      </div>
    </div>
    <button v-if="!barcodeSearchOpened" class="btn btn-light icon-btn ml-2" @click="openBarcodeSearch">
      <img class="barcode-scanner" src="/images/icon_small/barcode.png"/>
    </button>
  </div>
</template>

<script>
export default {
  name: 'RepositorySearchContainer',
  data() {
    return {
      barcodeSearchOpened: false,
      barcodeValue: '',
      searchOpened: false,
      value: ''
    }
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
      this.closeSearch();
      this.barcodeSearchOpened = true;
      this.$nextTick(() => {
        this.$refs.barcodeSearchInput.focus();
      });
    },
    openSearch() {
      this.clearValues();
      this.closeBarcodeSearch();
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
    }
  }
}
</script>
