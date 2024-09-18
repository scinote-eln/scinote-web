<template>
  <div class="pl-6" v-if="storageLocationsTree.length" v-for="storageLocationTree in storageLocationsTree"
       :key="storageLocationTree.storage_location.id">
    <div class="flex items-center">
      <i v-if="storageLocationTree.children.length > 0"
         :class="{'sn-icon-up': opendedStorageLocations[storageLocationTree.storage_location.id],
                  'sn-icon-down': !opendedStorageLocations[storageLocationTree.storage_location.id]}"
         @click="opendedStorageLocations[storageLocationTree.storage_location.id] = !opendedStorageLocations[storageLocationTree.storage_location.id]"
         class="sn-icon p-2 pr-1 cursor-pointer"></i>
      <i v-else class="sn-icon sn-icon-up p-2 pr-1 opacity-0"></i>
      <div @click="selectStorageLocation(storageLocationTree)"
           class="flex items-center pl-1 flex-1 gap-2"
           :class="{
             '!bg-sn-super-light-blue': storageLocationTree.storage_location.id == value,
             'text-sn-blue cursor-pointer hover:bg-sn-super-light-grey': (
               moveMode === 'locations' || storageLocationTree.storage_location.container
             )
          }">
        <i v-if="storageLocationTree.storage_location.container" class="sn-icon sn-icon-item"></i>
        <div class="flex-1 truncate p-2 pl-0" :title="storageLocationTree.storage_location.name">
          {{ storageLocationTree.storage_location.name }}
        </div>
      </div>
    </div>
    <MoveTree v-if="opendedStorageLocations[storageLocationTree.storage_location.id]"
              :storageLocationsTree="storageLocationTree.children"
              :value="value"
              :moveMode="moveMode"
              @selectStorageLocation="$emit('selectStorageLocation', $event)" />
  </div>
</template>

<script>
export default {
  name: 'MoveTree',
  emits: ['selectStorageLocation'],
  props: {
    storageLocationsTree: Array,
    value: Number,
    moveMode: String
  },
  components: {
    MoveTree: () => import('./move_tree.vue')
  },
  data() {
    return {
      opendedStorageLocations: {}
    };
  },
  methods: {
    selectStorageLocation(storageLocationTree) {
      if (this.moveMode === 'locations' || storageLocationTree.storage_location.container) {
        this.$emit('selectStorageLocation', storageLocationTree.storage_location.id);
      }
    }
  }
};
</script>
