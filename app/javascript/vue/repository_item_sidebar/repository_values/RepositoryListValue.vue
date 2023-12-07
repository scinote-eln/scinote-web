<template>
  <div id="repository-list-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate" :title="colName">
      {{ colName }}
    </div>
    <div>
      <select-search
        v-if="permissions?.can_manage && !inArchivedRepositoryRow"
        ref="DropdownSelector"
        @change="changeSelected"
        @update="update"
        :value="selected"
        :withClearButton="true"
        :withEditCursor="true"
        :options="options"
        :isLoading="isLoading"
        :placeholder="i18n.t('repositories.item_card.dropdown_placeholder')"
        :no-options-placeholder="i18n.t('repositories.item_card.dropdown_placeholder')"
        :searchPlaceholder="i18n.t('repositories.item_card.dropdown_placeholder')"
        customClass="!h-[38px] !pl-3 sci-cursor-edit"
        optionsClassName="max-h-[300px]"
      ></select-search>
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
import SelectSearch from "../../shared/legacy/select_search.vue";
import repositoryValueMixin from "./mixins/repository_value.js";

export default {
  name: "RepositoryListValue",
  components: {
    "select-search": SelectSearch
  },
  mixins: [repositoryValueMixin],
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object,
    optionsPath: String,
    permissions: null,
    inArchivedRepositoryRow: Boolean,
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

    $.get(this.optionsPath, data => {
      if (Array.isArray(data)) {
        this.options = data.map(option => {
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
      if (value) {
        this.update(value);
      }
    }
  }
};
</script>
