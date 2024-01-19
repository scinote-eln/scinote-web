<template>
  <div class="buttons">
    <template v-if="isWindows">
      <a :href="responseData[0]['url']"
         class="btn btn-primary new-project-btn"
         :title="i18n.t('users.settings.account.addons.desktop_app.windows_button')"
         role="button"
         data-remote="true"
         target="_blank">
        <span class="hidden-xs">{{ i18n.t('users.settings.account.addons.desktop_app.windows_button') }}</span>
      </a>
      <p class="text-xs mt-1" style="color: var(--sn-sleepy-grey);">
        {{ i18n.t('users.settings.account.addons.desktop_app.version', { version: this.responseData[0]['version']}) }}
      </p>
    </template>

    <template v-else-if="isMac">
      <a :href="responseData[1]['url']"
         class="btn btn-primary new-project-btn"
         :title="i18n.t('users.settings.account.addons.desktop_app.macos_button')"
         role="button"
         data-remote="true"
         target="_blank">
        <span class="hidden-xs">{{ i18n.t('users.settings.account.addons.desktop_app.macos_button') }}</span>
      </a>
      <p class="text-xs mt-1" style="color: var(--sn-sleepy-grey);">
        {{ i18n.t('users.settings.account.addons.desktop_app.version', { version: this.responseData[1]['version']}) }}
      </p>
    </template>

    <template v-else>
      <div class="flex">
        <div>
          <a :href="responseData[0]['url']"
             class="btn btn-primary new-project-btn"
             :title="i18n.t('users.settings.account.addons.desktop_app.windows_button')"
             role="button"
             data-remote="true"
             target="_blank">
            <span class="hidden-xs">{{ i18n.t('users.settings.account.addons.desktop_app.windows_button') }}</span>
          </a>
          <p class="text-xs mt-1" style="color: var(--sn-sleepy-grey);">
            {{ i18n.t('users.settings.account.addons.desktop_app.version',
              { version: this.responseData[0]['version']})
            }}
          </p>
        </div>

        <div class="ml-2">
          <a :href="responseData[1]['url']"
             class="btn btn-primary new-project-btn"
             :title="i18n.t('users.settings.account.addons.desktop_app.macos_button')"
             role="button"
             data-remote="true"
             target="_blank">
            <span class="hidden-xs">{{ i18n.t('users.settings.account.addons.desktop_app.macos_button') }}</span>
          </a>
          <p class="text-xs mt-1" style="color: var(--sn-sleepy-grey);">
            {{ i18n.t('users.settings.account.addons.desktop_app.version',
              { version: this.responseData[1]['version']})
            }}
          </p>
        </div>
      </div>
    </template>

    <a :href="'https://knowledgebase.scinote.net/en/knowledge/how-to-use-scinote-edit'"
        :title="i18n.t('users.settings.account.addons.more_info')"
        target="_blank">
      <span class="sn-icon sn-icon-open"></span>
      {{ i18n.t('users.settings.account.addons.more_info') }}
    </a>
  </div>
</template>

<script>
export default {
  name: 'ScinoteEditDownload',
  props: {
    data: { type: String, required: true }
  },
  data() {
    return {
      userAgent: this.data,
      responseData: {}
    };
  },
  computed: {
    isWindows() {
      return /Windows/.test(this.userAgent);
    },
    isMac() {
      return /Mac OS/.test(this.userAgent);
    }
  },
  created() {
    window.scinoteEditDownload = this;
    this.fetchData();
  },
  beforeUnmount() {
    delete window.scinoteEditDownloadComponent;
  },
  methods: {
    fetchData() {
      $.get('https://extras.scinote.net/scinote-edit/latest.json', (result) => {
        this.responseData = result;
      });
    }
  }
};
</script>
