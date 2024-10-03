import axios from '../../../packs/custom_axios.js';
import MoveTree from './move_tree.vue';
import {
  tree_storage_locations_path
} from '../../../routes.js';

export default {
  mounted() {
    axios.get(this.storageLocationsTreeUrl).then((response) => {
      this.storageLocationsTree = response.data;
      this.dataLoaded = true;
    });
  },
  data() {
    return {
      selectedStorageLocationId: null,
      storageLocationsTree: [],
      query: '',
      dataLoaded: false
    };
  },
  computed: {
    storageLocationsTreeUrl() {
      return tree_storage_locations_path({ format: 'json', container: this.container });
    },
    filteredStorageLocationsTree() {
      if (this.query === '') {
        return this.storageLocationsTree;
      }

      return this.filteredStorageLocationsTreeHelper(this.storageLocationsTree);
    }
  },
  components: {
    MoveTree
  },
  methods: {
    filteredStorageLocationsTreeHelper(storageLocationsTree) {
      return storageLocationsTree.map(({ storage_location, children, can_manage }) => {
        if (storage_location.name.toLowerCase().includes(this.query.toLowerCase())) {
          return { storage_location, children, can_manage };
        }

        const filteredChildren = this.filteredStorageLocationsTreeHelper(children);
        return filteredChildren.length ? { storage_location, can_manage, children: filteredChildren } : null;
      }).filter(Boolean);
    },
    selectStorageLocation(storageLocationId) {
      this.selectedStorageLocationId = storageLocationId;
    }
  }
};
