import axios from '../../../packs/custom_axios.js';
import MoveTree from './move_tree.vue';
import {
  tree_storage_locations_path
} from '../../../routes.js';

export default {
  mounted() {
    axios.get(this.storageLocationTreeUrl).then((response) => {
      this.storageLocationTree = response.data;
    });
  },
  data() {
    return {
      selectedStorageLocationId: null,
      storageLocationTree: [],
      query: ''
    };
  },
  computed: {
    storageLocationTreeUrl() {
      return tree_storage_locations_path({ format: 'json', container: this.container });
    },
    filteredStorageLocationTree() {
      if (this.query === '') {
        return this.storageLocationTree;
      }

      return this.storageLocationTree.map((storageLocation) => (
        {
          storage_location: storageLocation.storage_location,
          children: storageLocation.children.filter((child) => (
            child.storage_location.name.toLowerCase().includes(this.query.toLowerCase())
          ))
        }
      )).filter((storageLocation) => (
        storageLocation.storage_location.name.toLowerCase().includes(this.query.toLowerCase())
        || storageLocation.children.length > 0
      ));
    }
  },
  components: {
    MoveTree
  },
  methods: {
    selectStorageLocation(storageLocationId) {
      this.selectedStorageLocationId = storageLocationId;
    }
  }
};
