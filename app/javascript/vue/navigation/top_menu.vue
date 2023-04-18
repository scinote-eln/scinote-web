<template>
  <div class="sci--navigation--top-menu-container">
    <div class="sci--navigation--top-menu-logo">
      <a v-if="rootUrl && logo" :title="i18n.t('nav.label.scinote')" :href="rootUrl">
        <img class="logo small" :src="logo.small_url">
        <img class="logo large" :src="logo.large_url">
      </a>
    </div>
    <div v-if="teams" class="sci--navigation--top-menu-teams">
      <DropdownSelector
        :selectedValue="current_team"
        :options="teams"
        :disableSearch="true"
        :selectorId="`sciNavigationTeamSelector`"
        :labelHTML="true"
        @dropdown:changed="switchTeam"
      />
    </div>
    <div v-if="user" class="sci--navigation--top-menu-search left-icon sci-input-container">
      <input type="text" class="sci-input-field" :placeholder="i18n.t('nav.search')" @change="searchValue"/>
      <i class="fas fa-search"></i>
    </div>
    <div v-if="user" class="dropdown">
      <button class="btn btn-light icon-btn" data-toggle="dropdown">
        <i class="fas fa-question-circle"></i>
      </button>
      <ul v-if="user" class="dropdown-menu dropdown-menu-right">
        <li v-for="(item, i) in helpMenu">
          <a :key="i" :href="item.url">
            {{ item.name }}
          </a>
        </li>
      </ul>
    </div>
    <div v-if="user" class="dropdown">
      <button class="btn btn-light icon-btn" data-toggle="dropdown">
        <i class="fas fa-cog"></i>
      </button>
      <ul class="dropdown-menu dropdown-menu-right">
        <li v-for="(item, i) in settingsMenu">
          <a :key="i" :href="item.url">
            {{ item.name }}
          </a>
        </li>
        <li>
          <a href="" data-toggle='modal' data-target='#aboutModal' >
          {{ i18n.t('left_menu_bar.support_links.core_version') }}
          </a>
        </li>
      </ul>
    </div>
    <div v-if="user" class="sci--navigation--notificaitons-flyout-container">
      <button class="btn btn-light icon-btn"
              :class="{ 'has-unseen': unseenNotificationsCount > 0 }"
              :data-unseen="unseenNotificationsCount"
              data-toggle="dropdown"
              @click="notificationsOpened = !notificationsOpened">
        <i class="fas fa-bell"></i>
      </button>
      <div v-if="notificationsOpened" class="sci--navigation--notificaitons-flyout-backdrop" @click="notificationsOpened = false"></div>
      <NotificationsFlyout
        v-if="notificationsOpened"
        :notificationsUrl="notificationsUrl"
        :unseenNotificationsCount="unseenNotificationsCount"
        @update:unseenNotificationsCount="checkUnseenNotifications()"
        @close="notificationsOpened = false" />
    </div>
    <div v-if="user" class="dropdown">
      <div class="sci--navigation--top-menu-user" data-toggle="dropdown">
        <span>{{ i18n.t('nav.user_greeting', { full_name: user.name })}}</span>
        <img class="avatar" :src="user.avatar_url">
      </div>
      <div class="dropdown-menu dropdown-menu-right">
        <li v-for="(item, i) in userMenu">
          <a :key="i" :href="item.url">
            {{ item.name }}
          </a>
        </li>
        <li>
          <a rel="nofollow" data-method="delete" :href="user.sign_out_url">
            {{ i18n.t('nav.user.logout') }}
          </a>
        </li>
      </div>
    </div>
  </div>
</template>

<script>
  import NotificationsFlyout from './notifications/notifications_flyout.vue'
  import DropdownSelector from '../shared/dropdown_selector.vue'

  export default {
    name: 'TopMenuContainer',
    components: {
      DropdownSelector,
      NotificationsFlyout
    },
    props: {
      url: String,
      notificationsUrl: String,
      unseenNotificationsUrl: String
    },
    data() {
      return {
        rootUrl: null,
        logo: null,
        current_team: null,
        teams: null,
        searchUrl: null,
        user: null,
        helpMenu: null,
        settingsMenu: null,
        userMenu: null,
        showAboutModal: false,
        notificationsOpened: false,
        unseenNotificationsCount: 0
      }
    },
    created() {
      $.get(this.url, (result) => {
        this.rootUrl = result.root_url;
        this.logo = result.logo;
        this.current_team = result.current_team;
        this.teams = result.teams;
        this.searchUrl = result.search_url;
        this.helpMenu = result.help_menu;
        this.settingsMenu = result.settings_menu;
        this.userMenu = result.user_menu;
        this.user = result.user;
      })

      this.checkUnseenNotifications();

      $(document).on('turbolinks:load', () => {
        this.notificationsOpened = false;
        this.checkUnseenNotifications();
      })
    },
    methods: {
      switchTeam(team) {
        if (this.current_team == team) return;

        $.post(this.teams.find(e => e.value == team).params.switch_url, (result) => {
          this.current_team = result.current_team
          dropdownSelector.selectValues('#sciNavigationTeamSelector', this.current_team);
          window.open(this.rootUrl, '_self')
        }).error((msg) => {
          HelperModule.flashAlertMsg(msg.responseJSON.message, 'danger');
        });
      },
      searchValue(e) {
        window.open(`${this.searchUrl}?q=${e.target.value}`, '_self')
      },
      checkUnseenNotifications() {
        $.get(this.unseenNotificationsUrl, (result) => {
          this.unseenNotificationsCount = result.unseen;
        })
      }
    }
  }
</script>
