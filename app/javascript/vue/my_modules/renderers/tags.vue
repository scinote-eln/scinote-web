<template>
  <div class="flex items-center gap-1.5 h-9 mt-0.5">
    <template v-if="params.data.tags.length > 0 || params.data.permissions.assign_tags">
      <GeneralDropdown v-if="params.data.tags.length > 0">
        <template v-slot:field>
          <div class="flex items-center gap-1.5">
            <div
                class="sci-tag max-w-[150px]"
                :class="tagTextColor(params.data.tags[0].color)"
                :style="{'background': params.data.tags[0].color}">
              <div class="truncate">{{ params.data.tags[0].name }}</div>
            </div>
            <div v-if="params.data.tags.length > 1"
                class="flex shrink-0 items-center justify-center w-7 h-7 text-xs rounded-full bg-sn-dark-grey text-sn-white">
              <span>+{{ params.data.tags.length - 1 }}</span>
            </div>
          </div>
        </template>
        <template v-slot:flyout>
          <div>
            {{ i18n.t('experiments.table.used_tags') }}
          </div>
          <hr class="my-2" />
          <div class="max-h-[200px] overflow-y-auto flex flex-wrap gap-1.5 max-w-[240px]">
            <div v-for="tag in params.data.tags" :key="tag.id"
                class="sci-tag max-w-[150px]"
                :class="tagTextColor(tag.color)"
                :style="{'background': tag.color}">
              <div class="truncate">{{ tag.name }}</div>
            </div>
          </div>
        </template>
      </GeneralDropdown>
      <div v-if="params.data.permissions.assign_tags" @click.stop="openModal"
        class="flex items-center shrink-0 justify-center w-7 h-7 rounded-full border-dashed bg-sn-white text-sn-sleepy-grey border-sn-sleepy-grey">
        <i class="sn-icon sn-icon-new-task"></i>
    </div>
    </template>
    <span v-else>{{ i18n.t('experiments.table.not_set') }}</span>
  </div>
</template>
<script>

import GeneralDropdown from '../../shared/general_dropdown.vue';

export default {
  name: 'TagsRenderer',
  props: {
    params: {
      required: true
    }
  },
  components: {
    GeneralDropdown
  },
  methods: {
    openModal() {
      this.params.dtComponent.$emit('editTags', null, [this.params.data]);
    },
    tagTextColor(color) {
      return window.isColorBright(color) ? 'text-black' : 'text-white';
    },
  }
};
</script>
