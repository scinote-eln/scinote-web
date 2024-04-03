<template>
  <div class="pl-6" v-if="objects.length" v-for="object in objects" :key="object.folder.id">
    <div class="flex items-center">
      <i v-if="object.children.length > 0"
         :class="{'sn-icon-up': opendedFolders[object.folder.id], 'sn-icon-down': !opendedFolders[object.folder.id]}"
         @click="opendedFolders[object.folder.id] = !opendedFolders[object.folder.id]"
         class="sn-icon p-2 pr-1 cursor-pointer"></i>
      <i v-else class="sn-icon sn-icon-up p-2 pr-1 opacity-0"></i>
      <div @click="$emit('selectFolder', object.folder.id)"
           class="cursor-pointer flex items-center pl-1 flex-1 gap-2
                text-sn-blue hover:bg-sn-super-light-grey"
          :class="{'!bg-sn-super-light-blue': object.folder.id == value}">
        <i class="sn-icon sn-icon-folder"></i>
        <div class="flex-1 truncate p-2 pl-0" :title="object.folder.name">
          {{ object.folder.name }}
        </div>
      </div>
    </div>
    <MoveTree v-if="opendedFolders[object.folder.id]"
              :objects="object.children"
              :value="value"
              @selectFolder="$emit('selectFolder', $event)" />
  </div>
</template>

<script>
export default {
  name: 'MoveTree',
  emits: ['selectFolder'],
  props: {
    objects: Array,
    value: Number,
  },
  components: {
    MoveTree: () => import('./move_tree.vue')
  },
  data() {
    return {
      opendedFolders: {},
    };
  },
};
</script>
