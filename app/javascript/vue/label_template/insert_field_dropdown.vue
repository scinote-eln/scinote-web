<template>
  <div ref="dropdown" class="insert-field-dropdown dropdown">
    <a class="open-dropdown-button collapsed" role="button" data-toggle="dropdown"
       id="fieldsContainer" aria-expanded="false">
      {{ i18n.t('label_templates.show.insert_dropdown.button') }}
      <i class="fas fa-chevron-down"></i>
    </a>
    <div class="dropdown-menu dropdown-menu-right" aria-labelledby="fieldsContainer">
      <div class="search-container sci-input-container">
        <label>
          {{ i18n.t('label_templates.show.insert_dropdown.button') }}
        </label>
        <a class="close-dropdown hover:cursor-pointer" data-toggle="dropdown">{{ i18n.t('general.cancel')}}</a>
        <input v-model="searchValue"
               type="text"
               class="sci-input-field insert-field-dropdown autofocus" autofocus="true"
               :placeholder="i18n.t('label_templates.show.insert_dropdown.search_placeholder')" />
        <i class="fas fa-search relative left-60 bottom-7"></i>
      </div>
      <div class="fields-container">
        <div :key="`default_${index}`" v-for="(field, index) in filteredFields.default"
            data-toggle="tooltip"
            data-placement="right"
            :data-template="tooltipTemplate"
            class="field-element"
            :title="i18n.t('label_templates.show.insert_dropdown.field_code', {code: field.tag})"
            @click="insertTag(field)"
        >
          {{ field.key }}
          <i class="sn-icon sn-icon-plus-square"></i>
        </div>
        <div v-if="filteredFields.common.length" class="block-title">
          {{ i18n.t('label_templates.show.insert_dropdown.common_fields') }}
        </div>
        <div :key="`common_${index}`" v-for="(field, index) in filteredFields.common"
            data-toggle="tooltip"
            data-placement="right"
            :data-template="tooltipTemplate"
            class="field-element"
            :title="i18n.t('label_templates.show.insert_dropdown.field_code', {code: field.tag})"
            @click="insertTag(field)"
        >
          <i v-if="field.icon" :class="field.icon"></i>
          {{ field.key }}
          <i class="sn-icon sn-icon-plus-square"></i>
        </div>
        <div v-for="(repository, index) in filteredFields.repositories" :key="`repository_${index}`">
          <div class="block-title">
            {{ repository.repository_name }}
          </div>
          <div v-for="(field, index1) in repository.tags" :key="`repository_${index}_${index1}`"
            data-toggle="tooltip"
            data-placement="right"
            :data-template="tooltipTemplate"
            class="field-element"
            :title="i18n.t('label_templates.show.insert_dropdown.field_code', {code: field.tag})"
            @click="insertTag(field)"
          >
            {{ field.key }}
            <i class="sn-icon sn-icon-plus-square"></i>
          </div>
        </div>
        <div class="no-results" v-if="this.noResults">
          {{ i18n.t('label_templates.show.insert_dropdown.nothing_found') }}
        </div>
      </div>
    </div>
    <LogoInsertModal v-if="openLogoModal"
                     :unit="labelTemplate.attributes.unit"
                     :density="labelTemplate.attributes.density"
                     :dimension="logoDimension"
                     @insert:tag="insertTag"
                     @cancel="openLogoModal = false"/>
  </div>
</template>

<script>
import LogoInsertModal from './components/logo_insert_modal.vue';

export default {
  name: 'InsertFieldDropdown',
  props: {
    labelTemplate: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      fields: {
        default: [],
        common: [],
        repositories: []
      },
      openLogoModal: false,
      logoDimension: null,
      searchValue: ''
    };
  },
  components: { LogoInsertModal },
  computed: {
    tooltipTemplate() {
      return `<div class="tooltip" role="tooltip">
                  <div class="tooltip-arrow"></div>
                  <div class="tooltip-body">
                    <div class="tooltip-inner"></div>
                  </div>
                </div>`;
    },
    filteredFields() {
      this.$nextTick(() => {
        $('.tooltip').remove();
        $('[data-toggle="tooltip"]').tooltip();
      });

      if (this.searchValue.length == 0) {
        return this.fields;
      }
      return {
        default: this.filterArray(this.fields.default, 'key'),
        common: this.filterArray(this.fields.common, 'key'),
        repositories: this.filterArray(this.fields.repositories, 'repository_name').map((repo) => ({ ...repo, tags: this.filterArray(repo.tags, 'key') }))
      };
    },
    noResults() {
      return this.filteredFields.default.concat(this.filteredFields.common, this.filteredFields.repositories).length === 0;
    }
  },
  mounted() {
    $.get(this.labelTemplate.attributes.urls.fields, (result) => {
      result.default.map((value) => {
        value.key = this.i18n.t(`label_templates.default_columns.${value.key}`);
        return value;
      });

      this.fields = result;
      this.$nextTick(() => {
        $('[data-toggle="tooltip"]').tooltip();
      });
    });
    this.$nextTick(() => {
      $(this.$refs.dropdown).on('show.bs.dropdown', () => {
        this.$nextTick(() => {
          $('.insert-field-dropdown')[1].focus();
        });
        this.searchValue = '';
      });
    });
  },
  methods: {
    insertTag(field) {
      if (field.id == 'logo') {
        this.logoDimension = field.dimension;
        this.openLogoModal = true;
        return;
      }
      this.$emit('insertTag', field.tag);
    },
    filterArray(array, key) {
      return array.filter((field) => (
        field[key].toLowerCase().indexOf(this.searchValue.toLowerCase()) !== -1
            || field.tags
      ));
    }
  }
};
</script>
