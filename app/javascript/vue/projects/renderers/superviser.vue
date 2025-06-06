<template>
  <div v-if="params.data.supervised_by">
    <GeneralDropdown v-if="canManage" @open="loadUsers" @close="closeFlyout" position="right">
      <template v-slot:field>
        <div class="flex items-center gap-1 cursor-pointer h-9">
          <div v-if="params.data.supervised_by.id" class="flex items-center gap-2" :title="params.data.supervised_by.name">
            <img :src="params.data.supervised_by.avatar" class="w-7 h-7 rounded-full" />
            <span>{{ params.data.supervised_by.name }}</span>
          </div>
          <div v-else class="flex items-center shrink-0 justify-center w-7 h-7 rounded-full border-dashed bg-sn-white text-sn-sleepy-grey border-sn-sleepy-grey">
            <i class="sn-icon sn-icon-new-task"></i>
          </div>
        </div>
      </template>
      <template v-slot:flyout>
        <div class="px-2">
          <div class="sci-input-container-v2 left-icon mb-1 -mx-2.5">
            <input type="text"
                    ref="searchInput"
                    v-model="query"
                    class="sci-input-field"
                    autofocus="true"
                    :placeholder="i18n.t('general.search')" />
            <i class="sn-icon sn-icon-search"></i>
          </div>
        </div>
        <div class="flex flex-col relative max-h-80 overflow-y-auto max-w-[280px] pt-1 -mx-2.5 px-2 gap-y-px">
          <div v-for="user in allUsers"
              :key="user[0]"
              @click="selectUser(user)"
              :class="{
                '!bg-sn-super-light-blue': user[0] === params.data.supervised_by.id
              }"
              class="whitespace-nowrap rounded py-2.5 px-2 flex cursor-pointer items-center gap-2
                      hover:no-underline hover:bg-sn-super-light-grey leading-5"
            >
              <img :src="user[2].avatar_url" class="w-7 h-7 rounded-full" />
              <span class="truncate">{{ user[1] }}</span>
          </div>
        </div>
      </template>
    </GeneralDropdown>
    <div v-else>
      <div v-if="params.data.supervised_by.id" class="flex items-center gap-2" :title="params.data.supervised_by.name">
        <img :src="params.data.supervised_by.avatar" class="w-7 h-7 rounded-full" />
        <span>{{ params.data.supervised_by.name }}</span>
      </div>
    </div>
  </div>
</template>

<script>

import axios from '../../../packs/custom_axios.js';
import GeneralDropdown from '../../shared/general_dropdown.vue';

export default {
  name: 'DesignatedUsersRenderer',
  props: {
    params: {
      required: true
    }
  },
  components: {
    GeneralDropdown
  },
  data() {
    return {
      allUsers: [],
      query: ''
    };
  },
  watch: {
    query() {
      this.loadUsers();
    }
  },
  mounted() {
    this.$nextTick(() => {
      if (this.$refs.searchInput) {
        this.$refs.searchInput.focus();
      }
    });
  },
  computed: {
    canManage() {
      return this.params.data.urls.assigned_users && !this.params.data.archived_on;
    }
  },
  methods: {
    loadUsers() {
      axios.get(this.params.data.urls.assigned_users, {
        params: {
          query: this.query
        }
      })
        .then((response) => {
          const result = response.data.data;
          this.allUsers = result;
        });
    },
    closeFlyout() {
      this.query = '';
    },
    selectUser(user) {
      if (user[0] === this.params.data.supervised_by.id) {
        this.params.dtComponent.$emit('changeSuperviser', [''], this.params);
        return;
      }
      this.params.dtComponent.$emit('changeSuperviser', user, this.params);
    }
  }
};
</script>
