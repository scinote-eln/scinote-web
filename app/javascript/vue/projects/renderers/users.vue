<template>
  <div v-if="!params.data.folder" class="flex items-center gap-1 cursor-pointer h-9" @click="openAccessModal">
    <div v-for="(user, i) in visibleUsers" :key="i" :title="user.full_name">
      <img :src="user.avatar" class="w-7 h-7 rounded-full" />
    </div>
    <div v-if="hiddenUsers.length > 0" :title="hiddenUsersTitle"
        class="flex shrink-0 items-center justify-center w-7 h-7 text-xs rounded-full bg-sn-dark-grey text-sn-white">
      +{{ hiddenUsers.length }}
    </div>
    <div v-if="params.data.permissions['manage_users_assignments']"
        class="flex items-center shrink-0 justify-center w-7 h-7 rounded-full bg-sn-light-grey text-sn-dark-grey">
      <i class="sn-icon sn-icon-new-task"></i>
    </div>
  </div>
</template>

<script>
export default {
  name: 'UsersRenderer',
  props: {
    params: {
      required: true,
    },
  },
  computed: {
    users() {
      return this.params.value || [];
    },
    visibleUsers() {
      return this.users.slice(0, 4);
    },
    hiddenUsers() {
      return this.users.slice(4);
    },
    hiddenUsersTitle() {
      return this.hiddenUsers.map((user) => user.full_name).join('\u000d');
    }
  },
  methods: {
    openAccessModal() {
      this.params.dtComponent.$emit('access', {}, [this.params.data]);
    }
  }
};
</script>
