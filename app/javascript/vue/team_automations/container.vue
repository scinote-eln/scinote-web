<template>
  <div class="text-sn-dark-grey mb-4 max-w-3xl">
    <p>{{ i18n.t("team_automations.description") }}</p>
  </div>

  <div v-if="teamObject?.teamAutomationGroups">
    <div class="flex flex-col gap-8 mb-4">
      <div v-for="(subGroups, group) in teamObject.teamAutomationGroups" :key="group">
        <h2 class="mt-0">{{ i18n.t(`team_automations.groups.${group}`) }}</h2>
        <div class="flex flex-col bg-sn-white gap-4 p-4 w-full rounded">
          <div v-for="(subGroupElements, subGroup) in subGroups" :key="subGroup">
            <h5>{{ i18n.t(`team_automations.sub_groups.${subGroup}`) }}</h5>
            <div v-for="(subGroupElement, i) in subGroupElements" :key="subGroupElement" class="flex justify-between max-w-3xl border-0 border-t border-solid border-sn-super-light-grey">
              <div class="text-base py-3 pl-2">
                {{ i18n.t(`team_automations.sub_group_element.${subGroupElement}`) }}
              </div>
              <div class="flex-shrink-0 flex items-center py-3">
                <div class="sci-toggle-checkbox-container">
                  <input v-model="teamAutomationSettings[group][subGroup][subGroupElement]" type="checkbox" class="sci-toggle-checkbox" @change="setTeamAutomationsSettings"/>
                  <label class="sci-toggle-checkbox-label"></label>
                </div>
              </div>
            </div>
          </div>
        </div>  
      </div>
    </div>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';


export default {
  name: 'TeamAutomationsSettingsContainer',
  components: {},
  props: {
    teamUrl: String,
  },
  data() {
    return {
      teamObject: null,
      teamAutomationSettings: null
    };
  },
  created() {
    this.loadTeam();
  },
  computed: {
    emptySettings() {
      const result = {};

      for (const [group, subGroups] of Object.entries(this.teamObject.teamAutomationGroups)) {
        result[group] = {};

        for (const [subGroup, settingsArray] of Object.entries(subGroups)) {
          result[group][subGroup] = {};

          settingsArray.forEach(setting => {
            result[group][subGroup][setting] = false;
          });
        }
      }

      return result;
    }
  },
  methods: {
    loadTeam() {
      axios.get(this.teamUrl).then((response) => {
        this.teamObject = response.data;
        this.teamAutomationSettings = Object.fromEntries(
          Object.keys(this.emptySettings).map(key => [
            key,
            { ...this.emptySettings[key], ...(this.teamObject.teamSettings?.team_automation_settings || {})[key] }
          ])
        );
      });
    },
    setTeamAutomationsSettings() {
      axios.put(this.teamObject.updateUrl, {
        team: { team_automation_settings: this.teamAutomationSettings }
      });
    }
  }
};

</script>

