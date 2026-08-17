import axios from '../../../../packs/custom_axios';
import ActionCableConsumer from '../../../../channels/consumer';

// Keep this comfortably below EditingFlag::DEFAULT_DURATION (30s) server-side, so a single
// missed heartbeat (network blip, tab throttled in the background) doesn't expire the flag.
const REFRESH_INTERVAL_MS = 10000;

export default {
  data() {
    return {
      editingFlags: {},
      ownEditingFlagIds: {},
      editingFlagSubscriptions: {},
      editingFlagRefreshIntervals: {},
      editingIntentByElementId: {}
    };
  },
  watch: {
    elements: {
      deep: true,
      handler(newElements) {
        this.syncEditingFlagSubscriptions(newElements || []);
      }
    }
  },
  mounted() {
    this.syncEditingFlagSubscriptions(this.elements || []);
  },
  beforeUnmount() {
    Object.values(this.editingFlagSubscriptions).forEach((subscription) => {
      ActionCableConsumer.subscriptions.remove(subscription);
    });
    Object.values(this.editingFlagRefreshIntervals).forEach((interval) => clearInterval(interval));
    // Turbolinks keeps the JS runtime alive across navigations, so a flag we own has to be
    // destroyed explicitly here or it would keep looking "active" until it times out server-side.
    Object.values(this.ownEditingFlagIds).forEach((editingFlagId) => {
      axios.delete(`/editing_flags/${editingFlagId}`);
    });
  },
  methods: {
    editingFlagsFor(elementId) {
      return Object.values(this.editingFlags[elementId] || {});
    },
    syncEditingFlagSubscriptions(elements) {
      const elementIds = elements.map((element) => String(element.id));

      Object.keys(this.editingFlagSubscriptions)
        .filter((elementId) => !elementIds.includes(elementId))
        .forEach((elementId) => this.unsubscribeFromEditingFlags(elementId));

      elements.forEach((element) => this.subscribeToEditingFlags(element));
    },
    subscribeToEditingFlags(element) {
      if (this.editingFlagSubscriptions[element.id]) return;

      this.editingFlagSubscriptions = {
        ...this.editingFlagSubscriptions,
        [element.id]: ActionCableConsumer.subscriptions.create(
          {
            channel: 'EditingFlagsChannel',
            subject_type: element.attributes.orderable_type,
            subject_id: element.attributes.orderable.id
          },
          {
            received: (message) => this.receiveEditingFlag(element.id, message)
          }
        )
      };

      this.loadEditingFlags(element);
    },
    loadEditingFlags(element) {
      axios.get('/editing_flags', {
        params: {
          subject_type: element.attributes.orderable_type,
          subject_id: element.attributes.orderable.id
        }
      }).then((response) => {
        const elementFlags = { ...(this.editingFlags[element.id] || {}) };
        response.data.data.forEach((flag) => { elementFlags[flag.id] = flag; });
        this.editingFlags = { ...this.editingFlags, [element.id]: elementFlags };
      });
    },
    unsubscribeFromEditingFlags(elementId) {
      const subscription = this.editingFlagSubscriptions[elementId];
      if (subscription) {
        ActionCableConsumer.subscriptions.remove(subscription);

        const editingFlagSubscriptions = { ...this.editingFlagSubscriptions };
        delete editingFlagSubscriptions[elementId];
        this.editingFlagSubscriptions = editingFlagSubscriptions;
      }

      const editingFlags = { ...this.editingFlags };
      delete editingFlags[elementId];
      this.editingFlags = editingFlags;

      // The element (step/result orderable) is gone from our list, e.g. deleted, archived
      // or moved elsewhere while it was still being edited - make sure we don't leave a
      // heartbeat running or an orphaned flag behind for it.
      this.stopEditingFlagRefresh(elementId);

      const editingIntentByElementId = { ...this.editingIntentByElementId };
      delete editingIntentByElementId[elementId];
      this.editingIntentByElementId = editingIntentByElementId;

      const editingFlagId = this.ownEditingFlagIds[elementId];
      if (editingFlagId) {
        axios.delete(`/editing_flags/${editingFlagId}`);

        const ownEditingFlagIds = { ...this.ownEditingFlagIds };
        delete ownEditingFlagIds[elementId];
        this.ownEditingFlagIds = ownEditingFlagIds;
      }
    },
    receiveEditingFlag(elementId, message) {
      const flag = message.editing_flag.data;
      const elementFlags = { ...(this.editingFlags[elementId] || {}) };

      if (message.action === 'destroy') {
        delete elementFlags[flag.id];
      } else {
        elementFlags[flag.id] = flag;
      }

      this.editingFlags = { ...this.editingFlags, [elementId]: elementFlags };
    },
    createEditingFlag(element) {
      this.editingIntentByElementId = { ...this.editingIntentByElementId, [element.id]: true };

      axios.post('/editing_flags', {
        subject_type: element.attributes.orderable_type,
        subject_id: element.attributes.orderable.id
      }).then((response) => {
        const editingFlagId = response.data.data.id;

        // destroyEditingFlag may have already run for this element while this request was
        // in flight (fast focus/blur) - don't resurrect a heartbeat nobody wants anymore.
        if (!this.editingIntentByElementId[element.id]) {
          axios.delete(`/editing_flags/${editingFlagId}`);
          return;
        }

        this.ownEditingFlagIds = { ...this.ownEditingFlagIds, [element.id]: editingFlagId };
        this.startEditingFlagRefresh(element);
      });
    },
    destroyEditingFlag(element) {
      const editingIntentByElementId = { ...this.editingIntentByElementId };
      delete editingIntentByElementId[element.id];
      this.editingIntentByElementId = editingIntentByElementId;

      this.stopEditingFlagRefresh(element.id);

      const editingFlagId = this.ownEditingFlagIds[element.id];
      if (!editingFlagId) return;

      axios.delete(`/editing_flags/${editingFlagId}`).then(() => {
        const ownEditingFlagIds = { ...this.ownEditingFlagIds };
        delete ownEditingFlagIds[element.id];
        this.ownEditingFlagIds = ownEditingFlagIds;
      });
    },
    startEditingFlagRefresh(element) {
      this.stopEditingFlagRefresh(element.id);

      this.editingFlagRefreshIntervals = {
        ...this.editingFlagRefreshIntervals,
        [element.id]: setInterval(() => this.refreshEditingFlag(element), REFRESH_INTERVAL_MS)
      };
    },
    stopEditingFlagRefresh(elementId) {
      const interval = this.editingFlagRefreshIntervals[elementId];
      if (!interval) return;

      clearInterval(interval);

      const editingFlagRefreshIntervals = { ...this.editingFlagRefreshIntervals };
      delete editingFlagRefreshIntervals[elementId];
      this.editingFlagRefreshIntervals = editingFlagRefreshIntervals;
    },
    refreshEditingFlag(element) {
      const editingFlagId = this.ownEditingFlagIds[element.id];
      if (!editingFlagId) {
        this.stopEditingFlagRefresh(element.id);
        return;
      }

      axios.patch(`/editing_flags/${editingFlagId}/refresh`).catch(() => {
        this.stopEditingFlagRefresh(element.id);
      });
    }
  }
};
