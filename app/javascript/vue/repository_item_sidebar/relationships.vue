<template>
  <section id="relationships-section" class="flex flex-col" ref="relationshipsSectionRef">
    <div ref="relationships-label" id="relationships-label"
      class="font-inter text-lg font-semibold leading-7 mb-6 transition-colors duration-300">
      {{ i18n.t('repositories.item_card.section.relationships') }}
    </div>
    <div class="font-inter text-sm leading-5 w-full">
      <div class="flex flex-row justify-between mb-4">
        <div class="font-semibold" data-e2e="e2e-TX-itemCard-parents">
          {{ i18n.t('repositories.item_card.relationships.parents.count', { count: parentsCount || 0 }) }}
        </div>
        <a
          v-if="permissions.can_connect_rows"
          class="relationships-add-link btn-text-link font-normal"
          @click="handleOpenAddRelationshipsModal($event, 'parent')"
          data-e2e="e2e-BT-itemCard-addParent"
          >
          {{ i18n.t('repositories.item_card.add_relationship_button_text') }}
        </a>
      </div>
      <div v-if="parentsCount">
        <details v-for="(parent) in parents" @toggle="updateOpenState(parent.code, $event.target.open)" :key="parent.code" class="flex flex-col font-normal group cursor-default">
          <summary class="flex flex-row gap-3 mb-4 relative group">
            <img :src="icons.delimiter_path" class="w-3 h-3 cursor-pointer flex-shrink-0 relative top-1"
                 :class="{ 'rotate-90': relationshipDetailsState[parent.code] }" />
            <span>
              <span>{{ i18n.t('repositories.item_card.relationships.item') }}</span>
              <a v-if="parent.path" :href="parent.path" class="record-info-link btn-text-link !text-sn-science-blue">{{ parent.name }}</a>
              <span v-else>{{ parent.name }}</span>
              <button v-if="permissions.can_connect_rows && parent.can_connect_rows" @click="openUnlinkModal(parent)"
                      class=" ml-2 bg-transparent border-none opacity-0 group-hover:opacity-100 cursor-pointer">
                <img :src="icons.unlink_path" />
              </button>
            </span>
          </summary>
          <p class="flex flex-col gap-3 ml-6 mb-4">
            <span>
              {{ i18n.t('repositories.item_card.relationships.id', { code: parent.code }) }}
            </span>
            <span v-if="parent.repository_name && parent.repository_path">
              <span>{{ i18n.t('repositories.item_card.relationships.inventory') }}</span>
              <a :href="parent.repository_path" class="btn-text-link !text-sn-science-blue">
                {{ parent.repository_name }}
              </a>
            </span>
          </p>
        </details>
      </div>
      <div v-else class="text-sn-dark-grey max-h-5">
        {{ i18n.t('repositories.item_card.relationships.parents.empty') }}
      </div>
    </div>

    <div class="sci-divider pb-4"></div>

    <div class="font-inter text-sm leading-5 w-full">
      <div class="flex flex-row justify-between" :class="{ 'mb-4': childrenCount }">
        <div class="font-semibold" data-e2e="e2e-TX-itemCard-children">
          {{ i18n.t('repositories.item_card.relationships.children.count', { count: childrenCount || 0 }) }}
        </div>
        <a
          v-if="permissions.can_connect_rows"
          class="relationships-add-link btn-text-link font-normal"
          @click="handleOpenAddRelationshipsModal($event, 'child')"
          data-e2e="e2e-BT-itemCard-addChild"
          >
          {{ i18n.t('repositories.item_card.add_relationship_button_text') }}
        </a>
      </div>
      <div v-if="childrenCount">
        <details v-for="(child) in children" :key="child.code" @toggle="updateOpenState(child.code, $event.target.open)"
                 class="flex flex-col font-normal group-last-of-type:[&>p:last-child]:mb-0">
          <summary class="flex flex-row gap-3 mb-4 relative group"
                   :class="{ 'group-last-of-type:mb-0': !relationshipDetailsState[child.code] }">
            <img :src="icons.delimiter_path" class="w-3 h-3 flex-shrink-0 cursor-pointer relative top-1"
                 :class="{ 'rotate-90': relationshipDetailsState[child.code] }"/>
            <span class="group/child">
              <span>{{ i18n.t('repositories.item_card.relationships.item') }}</span>
              <a v-if="child.path" :href="child.path" class="record-info-link btn-text-link !text-sn-science-blue">{{ child.name }}</a>
              <span v-else>{{ child.name }}</span>
              <button v-if="permissions.can_connect_rows && child.can_connect_rows" @click="openUnlinkModal(child)"
                      class="ml-2 bg-transparent border-none opacity-0 group-hover:opacity-100 cursor-pointer">
                <img :src="icons.unlink_path" />
              </button>
            </span>
          </summary>
          <p class="flex flex-col gap-3 ml-6 mb-4">
            <span>{{ i18n.t('repositories.item_card.relationships.id', { code: child.code }) }}</span>
            <span v-if="child.repository_name && child.repository_path">
              <span>{{ i18n.t('repositories.item_card.relationships.inventory') }}</span>
              <a :href="child.repository_path" class="btn-text-link !text-sn-science-blue">
                {{ child.repository_name }}
              </a>
            </span>
          </p>
        </details>
      </div>
      <div v-else class="text-sn-dark-grey max-h-5">
        {{ i18n.t('repositories.item_card.relationships.children.empty') }}
      </div>
    </div>

    <Teleport to="body">
      <unlink-modal v-if="selectedToUnlink" @confirmed="unlinkItem" @close="closeUnlinkModal" />
    </Teleport>
  </section>
</template>

<script>
/* global HelperModule I18n */

import axios from '../../packs/custom_axios.js';
import UnlinkModal from './unlink_modal.vue';
import { relationships_repository_repository_row_path } from '../../routes.js';

export default {
  name: 'RepositoryItemRelationships',
  components: {
    'unlink-modal': UnlinkModal
  },
  inject: ['syncTableRow'],
  props: {
    repository: { type: Object, required: true },
    rowId: { type: [Number, String], required: true },
    rowName: { type: String, default: '' },
    permissions: { type: Object, default: () => ({}) },
    icons: { type: Object, default: () => ({}) },
    notification: { type: Object, default: null }
  },
  data() {
    return {
      parentsCount: 0,
      childrenCount: 0,
      parents: [],
      children: [],
      rowConnections: {},
      relationshipDetailsState: {},
      selectedToUnlink: null
    };
  },
  created() {
    this.load();
  },
  methods: {
    load() {
      if (!this.repository?.id || !this.rowId) return Promise.resolve();

      return axios.get(relationships_repository_repository_row_path(this.repository.id, this.rowId))
        .then((response) => {
          this.parentsCount = response.data.parents_count;
          this.childrenCount = response.data.children_count;
          this.parents = response.data.parents;
          this.children = response.data.children;
          this.rowConnections = response.data.row_connections;
        });
    },
    syncConnectionsCount() {
      this.syncTableRow({
        id: this.rowId,
        connections_count: `${this.parentsCount || 0} / ${this.childrenCount || 0}`
      });
    },
    handleOpenAddRelationshipsModal(event, relation) {
      event.stopPropagation();
      event.preventDefault();
      const addRelationCallback = (data, connectionRelation) => {
        if (connectionRelation === 'parent') {
          this.parentsCount = data.parents.length;
          this.parents = data.parents;
        }
        if (connectionRelation === 'child') {
          this.childrenCount = data.children.length;
          this.children = data.children;
        }
        this.syncConnectionsCount();
      };
      window.repositoryItemRelationshipsModal.show(
        {
          relation,
          addRelationCallback,
          optionUrls: { ...this.rowConnections },
          notificationIconPath: this.icons.notification_path,
          notification: this.notification,
          canConnectRows: this.permissions.can_connect_rows
        }
      );
    },
    updateOpenState(code, isOpen) {
      this.relationshipDetailsState[code] = isOpen;
    },
    openUnlinkModal(item) {
      this.selectedToUnlink = item;
    },
    closeUnlinkModal() {
      this.selectedToUnlink = null;
    },
    async unlinkItem() {
      try {
        await axios.delete(this.selectedToUnlink.unlink_path);
        HelperModule.flashAlertMsg(
          I18n.t(
            'repositories.item_card.relationships.unlink_modal.success',
            { from_connection: this.rowName, to_connection: this.selectedToUnlink.name }
          ),
          'success'
        );
        await this.load();
        this.syncConnectionsCount();
      } catch {
        HelperModule.flashAlertMsg(
          I18n.t(
            'repositories.item_card.relationships.unlink_modal.error',
            { from_connection: this.rowName, to_connection: this.selectedToUnlink.name }
          ),
          'danger'
        );
      } finally {
        this.selectedToUnlink = null;
      }
    }
  }
};
</script>
