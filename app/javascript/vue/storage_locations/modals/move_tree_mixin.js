import axios from '../../../packs/custom_axios.js';
import MoveTree from './move_tree.vue';
import {
  tree_storage_locations_path
} from '../../../routes.js';

export default {
  mounted() {
    axios.get(this.storageLocationsTreeUrl, { params: { team_id: this.teamId } }).then((response) => {
      this.storageLocationsTree = response.data.locations;
      this.movableToRoot = response.data.movable_to_root;
      if (!this.movableToRoot) {
        this.selectedStorageLocationId = -1;
      }
      this.dataLoaded = true;
    });
  },
  data() {
    return {
      selectedStorageLocationId: null,
      movableToRoot: false,
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
      if (!this.movableToRoot && storageLocationId === null) {
        return;
      }

      this.selectedStorageLocationId = storageLocationId;
    }
  }
};
