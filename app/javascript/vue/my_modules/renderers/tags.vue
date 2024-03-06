<template>
  <div class="flex items-center gap-1.5 h-9 mt-0.5">
    <template v-if="params.data.tags.length > 0 || params.data.permissions.manage_tags">
      <div v-if="params.data.tags.length > 0"
           class="h-6 px-1.5 flex items-center rounded text-white max-w-[150px]"
           :style="{'background': params.data.tags[0].color}">
        <div class="truncate">{{ params.data.tags[0].name }}</div>
      </div>
      <GeneralDropdown v-if="params.data.tags.length > 1" >
        <template v-slot:field>
          <div class="h-6 min-w-[24px] text-sn-dark-grey flex items-center justify-center rounded-full text-[.625rem]
                    bg-sn-light-grey border !border-sn-sleepy-grey cursor-pointer">
            <span>+{{ params.data.tags.length - 1 }}</span>
          </div>
        </template>
        <template v-slot:flyout>
          <div>
            {{ i18n.t('experiments.table.used_tags') }}
          </div>
          <hr class="my-2" />
          <div class="max-h-[200px] overflow-y-auto flex flex-wrap gap-1.5 max-w-[240px]">
            <div v-for="tag in params.data.tags" :key="tag.id"
                class="h-6 px-1.5 flex items-center rounded text-white max-w-[150px]"
                :style="{'background': tag.color}">
              <div class="truncate">{{ tag.name }}</div>
            </div>
          </div>
        </template>
      </GeneralDropdown>
      <div v-if="params.data.permissions.manage_tags" @click.stop="openModal"
        class="cursor-pointer text-sn-sleep-grey border !border-dashed h-6 w-6 flex items-center
               justify-center !border-sn-sleep-grey rounded-full ">
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
    }
  }
};
</script>
