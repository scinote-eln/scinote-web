<template>
  <div ref="container" id="repository-status-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate" :title="colName">
      {{ colName }}
    </div>
    <div>
      <SelectDropdown
        v-if="permissions?.can_manage && !inArchivedRepositoryRow"
        @change="changeSelected"
        :value="selected"
        ref="DropdownSelector"
        :options="options"
        :searchable="true"
        :placeholder="i18n.t('repositories.item_card.dropdown_placeholder')"
        :no-options-placeholder="i18n.t('repositories.item_card.dropdown_placeholder')"
        :data-e2e="'e2e-DD-repoItemSBcustomColumns-input' + colId"
      ></SelectDropdown>
      <div v-else-if="status && icon"
           class="flex flex-row items-center text-sn-dark-grey font-inter text-sm font-normal leading-5 gap-1.5">
        <div v-html="parseEmoji(icon)" class="flex h-6 w-6"></div>
        {{ status }}
      </div>
      <div
        v-else
        class="text-sn-dark-grey font-inter text-sm font-normal leading-5"
      >
        {{ i18n.t("repositories.item_card.repository_status_value.no_status") }}
      </div>
    </div>
  </div>
</template>

<script>
import twemoji from 'twemoji';
import SelectDropdown from '../../shared/select_dropdown.vue';
import repositoryValueMixin from './mixins/repository_value.js';

export default {
  name: 'RepositoryStatusValue',
  components: {
    SelectDropdown
  },
  mixins: [repositoryValueMixin],
  data() {
    return {
      id: null,
      icon: null,
      status: null,
      selected: null,
      isLoading: true,
      options: []
    };
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object,
    optionsPath: String,
    permissions: null,
    inArchivedRepositoryRow: Boolean
  },
  created() {
    if (!this.colVal) return;

    this.id = this.colVal.id;
    this.icon = this.colVal.icon;
    this.status = this.colVal.status;
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
    this.replaceEmojiesInDropdown();
  },
  methods: {
    changeSelected(id) {
      this.selected = id;
      if (id || id === null) {
        this.update(id);
        this.replaceEmojiesInDropdown();
      }
    },
    parseEmoji(content) {
      return twemoji.parse(content);
    },
    replaceEmojiesInDropdown() {
      setTimeout(() => {
        twemoji.size = '24x24';
        twemoji.base = '/images/twemoji/';
        twemoji.parse(this.$refs.container);
      }, 300);
    }
  }
};
</script>
