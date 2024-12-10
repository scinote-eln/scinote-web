<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center">
      <h3>{{ i18n.t(`forms.show.blocks.${editField.attributes.type}`) }}</h3>
      <div class="ml-auto flex items-center gap-3">
        <div class="flex items-center gap-2">
          <span class="sci-toggle-checkbox-container">
            <input type="checkbox"
                  class="sci-toggle-checkbox"
                  @change="updateField"
                  v-model="editField.attributes.required" />
            <span class="sci-toggle-checkbox-label"></span>
          </span>
          <span>{{ i18n.t('forms.show.required_label') }}</span>
        </div>
        <GeneralDropdown  position="right">
          <template v-slot:field>
            <button class="btn btn-secondary icon-btn">
              <i class="sn-icon sn-icon-more-hori"></i>
            </button>
          </template>
          <template v-slot:flyout>
            <div @click="deleteField" class="py-2.5 px-3 hover:bg-sn-super-light-grey cursor-pointer text-sn-delete-red">
              {{ i18n.t('forms.show.delete') }}
            </div>
          </template>
        </GeneralDropdown>
      </div>
    </div>
    <hr class="my-4 w-full">
    <div>
      <label class="sci-label">{{ i18n.t('forms.show.title_label') }}</label>
      <div class="sci-input-container-v2" :class="{ 'error': editField.attributes.name.length == 0 }"  >
        <input type="text" class="sci-input" v-model="editField.attributes.name" @change="updateField" :placeholder="i18n.t('forms.show.title_placeholder')" />
      </div>
    </div>
    <div>
      <label class="sci-label">{{ i18n.t('forms.show.description_label') }}</label>
      <div class="sci-input-container-v2" >
        <input type="text" class="sci-input" v-model="editField.attributes.description" @change="updateField" :placeholder="i18n.t('forms.show.description_placeholder')" />
      </div>
    </div>
    <hr class="my-4 w-full">
    <div class="bg-sn-super-light-grey rounded p-4">
      <div class="flex items-center gap-4">
        <h5>{{ i18n.t('forms.show.mark_as_na') }}</h5>
        <span class="sci-toggle-checkbox-container">
          <input type="checkbox"
                 class="sci-toggle-checkbox"
                 @change="updateField"
                 v-model="editField.attributes.allow_not_applicable" />
          <span class="sci-toggle-checkbox-label"></span>
        </span>
      </div>
      <div>{{ i18n.t('forms.show.mark_as_na_explanation') }}</div>
    </div>
  </div>
</template>

<script>
import GeneralDropdown from '../shared/general_dropdown.vue';

export default {
  name: 'EditField',
  props: {
    field: Object
  },
  components: {
    GeneralDropdown
  },
  data() {
    return {
      editField: { ...this.field }
    };
  },
  created() {
  },
  computed: {
    validField() {
      return this.editField.attributes.name.length > 0;
    }
  },
  methods: {
    updateField() {
      if (!this.validField) {
        return;
      }
      this.$emit('update', this.editField);
    },
    deleteField() {
      this.$emit('delete', this.editField);
    }
  }
};
</script>
