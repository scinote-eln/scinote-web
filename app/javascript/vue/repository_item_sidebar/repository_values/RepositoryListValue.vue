<template>
  <div id="repository-list-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate" :title="colName">
      {{ colName }}
    </div>
    <div>
      <SelectDropdown
        v-if="permissions?.can_manage && !inArchivedRepositoryRow"
        ref="DropdownSelector"
        @change="changeSelected"
        :value="selected"
        :options="options"
        :searchable="true"
        :clearable="true"
        :size="'sm'"
        :placeholder="i18n.t('repositories.item_card.dropdown_placeholder')"
        :no-options-placeholder="i18n.t('repositories.item_card.dropdown_placeholder')"
        :data-e2e="'e2e-IF-repoItemSBcustomColumns-input' + colId"
      ></SelectDropdown>
      <div v-else-if="text"
           class="text-sn-dark-grey font-inter text-sm font-normal leading-5"
      >
        {{ text }}
      </div>
      <div v-else
           class="text-sn-dark-grey font-inter text-sm font-normal leading-5"
      >
        {{ i18n.t("repositories.item_card.repository_list_value.no_list") }}
      </div>
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../../shared/select_dropdown.vue';
import repositoryValueMixin from './mixins/repository_value.js';

export default {
  name: 'RepositoryListValue',
  components: {
    SelectDropdown
  },
  mixins: [repositoryValueMixin],
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object,
    optionsPath: String,
    permissions: null,
    inArchivedRepositoryRow: Boolean
  },
  data() {
    return {
      id: null,
      text: null,
      selected: null,
      isLoading: true,
      options: []
    };
  },
  created() {
    this.id = this.colVal?.id;
    this.text = this.colVal?.text;
  },
  mounted() {
    this.isLoading = true;

    $.get(this.optionsPath, (data) => {
      if (Array.isArray(data)) {
        this.options = data.map((option) => {
          const { value, label } = option;
          return [value, label];
        });
        return false;
      }
      this.options = [];
    }).always(() => {
      this.isLoading = false;
      this.selected = this.id;
    });
  },
  methods: {
    changeSelected(value) {
      this.selected = value;
      this.update(value);
    }
  }
};
</script>
