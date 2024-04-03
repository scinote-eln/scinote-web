<template>
  <div class="sci--navigation--top-menu-container">
    <div v-if="user" class="sci--navigation--top-menu-search left-icon sci-input-container-v2" :class="{'disabled' : !currentTeam}" :title="i18n.t('nav.search')">
      <input type="text" :placeholder="i18n.t('nav.search')" @change="searchValue"/>
      <i class="sn-icon sn-icon-search"></i>
    </div>
    <div v-if="currentTeam" class="w-64">
      <SelectDropdown
        :value="currentTeam"
        :options="teams"
        @change="switchTeam"
      ></SelectDropdown>
    </div>
    <MenuDropdown
      class="ml-auto"
      v-if="settingsMenu && settingsMenu.length > 0"
      :listItems="settingsMenuItems"
      :title="i18n.t('nav.settings')"
      :btnClasses="'btn btn-light icon-btn btn-black'"
      :position="'right'"
      :btnIcon="'sn-icon sn-icon-settings'"
      :data-e2e="'e2e-DD-topMenu-settings'"
    ></MenuDropdown>
    <GeneralDropdown
      v-if="user"
      ref="notificationDropdown"
      position="right"
      class="sci--navigation--notificaitons-flyout-container">
      <template v-slot:field>
        <button class="btn btn-light icon-btn btn-black" :data-e2e="'e2e-DD-topMenu-notifications'"
              :title="i18n.t('nav.notifications.title')"
              :class="{ 'has-unseen': unseenNotificationsCount > 0 }"
              :data-unseen="unseenNotificationsCount"
              data-toggle="dropdown">
          <i class="sn-icon sn-icon-notifications"></i>
        </button>
      </template>
      <template v-slot:flyout >
        <NotificationsFlyout
          :preferencesUrl="user.preferences_url"
          :notificationsUrl="notificationsUrl"
          :unseenNotificationsCount="unseenNotificationsCount"
          @update:unseenNotificationsCount="checkUnseenNotifications()"
          @close="$refs.notificationDropdown.$refs.field.click();"/>
      </template>
    </GeneralDropdown>
    <div v-if="user" class="dropdown" :title="i18n.t('nav.user_profile')">
      <div class="sci--navigation--top-menu-user btn btn-light icon-btn btn-black" data-toggle="dropdown" data-e2e="e2e-DD-topMenu-avatar">
        <img class="avatar w-6 h-6" :src="user.avatar_url">
      </div>
      <div class="dropdown-menu dropdown-menu-right rounded !p-2.5 sn-shadow-menu-sm">
        <li v-for="(item, i) in userMenu" :key="i">
          <a :href="item.url" class="!px-3 !py-2.5 rounded hover:!bg-sn-super-light-grey !text-sn-blue block">
            {{ item.name }}
          </a>
        </li>
        <li>
          <a rel="nofollow" data-method="delete" :href="user.sign_out_url" class="!px-3 !py-2.5 rounded hover:!bg-sn-super-light-grey !text-sn-blue block">
            {{ i18n.t('nav.user.logout') }}
          </a>
        </li>
      </div>
    </div>
  </div>
</template>

<script>
/* global HelperModule */
import NotificationsFlyout from './notifications/notifications_flyout.vue';
import DropdownSelector from '../shared/legacy/dropdown_selector.vue';
import SelectDropdown from '../shared/select_dropdown.vue';
import MenuDropdown from '../shared/menu_dropdown.vue';
import GeneralDropdown from '../shared/general_dropdown.vue';

export default {
  name: 'TopMenuContainer',
  components: {
    DropdownSelector,
    NotificationsFlyout,
    SelectDropdown,
    MenuDropdown,
    GeneralDropdown
  },
  props: {
    url: String,
    notificationsUrl: String,
    unseenNotificationsUrl: String
  },
  data() {
    return {
      rootUrl: null,
      teamSwitchUrl: null,
      currentTeam: null,
      teams: null,
      searchUrl: null,
      user: null,
      helpMenu: null,
      settingsMenu: null,
      userMenu: null,
      unseenNotificationsCount: 0
    };
  },
  created() {
    this.fetchData();
    this.checkUnseenNotifications();

    $(document).on('turbolinks:load', () => {
      this.notificationsOpened = false;
      this.checkUnseenNotifications();
      this.refreshCurrentTeam();
    });

    // Track name update in user profile settings
    $(document).on('inlineEditing::updated', '.inline-editing-container[data-field-to-update="full_name"]', this.fetchData);
  },
  beforeUnmount() {
    clearTimeout(this.unseenNotificationsTimeout);
  },
  computed: {
    settingsMenuItems() {
      return this.settingsMenu.map((item) => ({ text: item.name, url: item.url })).concat(
        {
          text: this.i18n.t('left_menu_bar.support_links.core_version'),
          modalTarget: '#aboutModal',
          url: ''
        }
      );
    }
  },
  methods: {
    fetchData() {
      $.get(this.url, (result) => {
        this.rootUrl = result.root_url;
        this.teamSwitchUrl = result.team_switch_url;
        this.currentTeam = result.current_team;
        this.teams = result.teams;
        this.searchUrl = result.search_url;
        this.helpMenu = result.help_menu;
        this.settingsMenu = result.settings_menu;
        this.userMenu = result.user_menu;
        this.user = result.user;
      });
    },
    switchTeam(team) {
      if (this.currentTeam === team) return;

      const newTeam = this.teams.find((e) => e[0] === team);

      if (!newTeam) return;

      $.post(this.teamSwitchUrl, { team_id: team }, (result) => {
        this.currentTeam = result.current_team;
        $('body').attr('data-current-team-id', this.currentTeam);
        window.open(this.rootUrl, '_self');
      }).fail((msg) => {
        HelperModule.flashAlertMsg(msg.responseJSON.message, 'danger');
      });
    },
    searchValue(e) {
      window.open(`${this.searchUrl}?q=${e.target.value}`, '_self');
    },
    checkUnseenNotifications() {
      clearTimeout(this.unseenNotificationsTimeout);
      $.get(this.unseenNotificationsUrl, (result) => {
        this.unseenNotificationsCount = result.unseen;
        this.unseenNotificationsTimeout = setTimeout(this.checkUnseenNotifications, 30000);
      });
    },
    refreshCurrentTeam() {
      const newTeam = parseInt($('body').attr('data-current-team-id'), 10);
      if (newTeam !== this.currentTeam) {
        this.currentTeam = newTeam;
      }
    }
  }
};
</script>
