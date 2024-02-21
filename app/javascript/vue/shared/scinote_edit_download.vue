<template>
  <div class="buttons">
    <template v-if="isWindows">
      <a :href="getWindowsHref"
         class="btn btn-primary new-project-btn"
         :title="i18n.t('users.settings.account.addons.desktop_app.windows_button')"
         role="button"
         target="_blank">
        <span class="hidden-xs">{{ i18n.t('users.settings.account.addons.desktop_app.windows_button') }}</span>
      </a>
      <div v-if="showButtonLabel" class="text-xs pt-2 pb-6" style="color: var(--sn-sleepy-grey);">
        {{ i18n.t('users.settings.account.addons.desktop_app.version', { version: this.responseData[0]['version']}) }}
      </div>
    </template>

    <template v-else-if="isMac">
      <a :href="getMacHref"
         class="btn btn-primary new-project-btn"
         :title="i18n.t('users.settings.account.addons.desktop_app.macos_button')"
         role="button"
         target="_blank">
        <span class="hidden-xs">{{ i18n.t('users.settings.account.addons.desktop_app.macos_button') }}</span>
      </a>
      <div v-if="showButtonLabel" class="text-xs pt-2 pb-6" style="color: var(--sn-sleepy-grey);">
        {{ i18n.t('users.settings.account.addons.desktop_app.version', { version: this.responseData[1]['version']}) }}
      </div>
    </template>

    <template v-else>
      <div class="flex">
        <div>
          <a :href="getWindowsHref"
             class="btn btn-primary new-project-btn"
             :title="i18n.t('users.settings.account.addons.desktop_app.windows_button')"
             role="button"
             target="_blank">
            <span class="hidden-xs">{{ i18n.t('users.settings.account.addons.desktop_app.windows_button') }}</span>
          </a>
          <div v-if="showButtonLabel" class="text-xs pt-2 pb-6" style="color: var(--sn-sleepy-grey);">
            {{ i18n.t('users.settings.account.addons.desktop_app.version',
              { version: this.responseData[0]['version']})
            }}
          </div>
        </div>

        <div class="ml-2">
          <a :href="getMacHref"
             class="btn btn-primary new-project-btn"
             :title="i18n.t('users.settings.account.addons.desktop_app.macos_button')"
             role="button"
             target="_blank">
            <span class="hidden-xs">{{ i18n.t('users.settings.account.addons.desktop_app.macos_button') }}</span>
          </a>
          <p v-if="showButtonLabel" class="text-xs pt-2 pb-6" style="color: var(--sn-sleepy-grey);">
            {{ i18n.t('users.settings.account.addons.desktop_app.version',
              { version: this.responseData[1]['version']})
            }}
          </p>
        </div>
      </div>
    </template>

    <a v-if="!isUpdateVersionModal" :href="'https://knowledgebase.scinote.net/en/knowledge/how-to-use-scinote-edit'"
        :title="i18n.t('users.settings.account.addons.more_info')"
        class="text-sn-blue"
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
    data: { type: String, required: true },
    isUpdateVersionModal: { type: Boolean, required: false }
  },
  data() {
    return {
      userAgent: this.data,
      responseData: []
    };
  },
  computed: {
    isWindows() {
      return /Windows/.test(this.userAgent);
    },
    isMac() {
      return /Mac OS/.test(this.userAgent);
    },
    showButtonLabel() {
      return this.responseData && this.responseData.length > 0 && !this.isUpdateVersionModal;
    },
    getWindowsHref() {
      return this.responseData && this.responseData.length > 0 ? this.responseData[0].url : '#';
    },
    getMacHref() {
      return this.responseData && this.responseData.length > 0 ? this.responseData[1].url : '#';
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
