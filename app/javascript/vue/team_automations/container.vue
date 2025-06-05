<template>
  <div class="text-sn-dark-grey mb-4 max-w-3xl">
    <p>{{ i18n.t("team_automations.description") }}</p>
  </div>

  <div v-if="teamObject?.teamAutomationGroups">
    <div class="flex flex-col gap-8 mb-4">
      <template v-for="(_subGroups, group) in teamObject?.teamAutomationGroups" :key="group">
        <div>
          <h2 class="mt-0">{{ i18n.t(`team_automations.groups.${group}`) }}</h2>
          <template v-for="(subGroupElements, subGroup) in teamObject?.teamAutomationGroups[group]" :key="subGroup">
            <table class="bg-sn-white w-full">
              <tbody>
                <tr class="text-base">
                  <td colspan=2 class="pl-4"><h5>{{ i18n.t(`team_automations.sub_groups.${subGroup}`) }}</h5></td>
                </tr>
                <template v-for="(subGroupElement, i) in subGroupElements" :key="subGroupElement">
                  <tr class="text-base">
                    <td class="py-3 pl-6">{{ i18n.t(`team_automations.sub_group_element.${subGroupElement}`) }}</td>
                    <td class="p-3">
                      <div class="sci-toggle-checkbox-container">
                        <input v-model="teamAutomationSettings[subGroupElement]" type="checkbox" class="sci-toggle-checkbox" @change="setTeamAutomationsSettings"/>
                        <label class="sci-toggle-checkbox-label"></label>
                      </div>
                    </td>
                  </tr>
                </template>
              </tbody>
            </table>
          </template>
        </div>
      </template>
    </div>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';


export default {
  name: 'StorageLocationsContainer',
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
      return Object.entries(this.teamObject.teamAutomationGroups).reduce((settings, [_group, subGroups]) => {
        Object.values(subGroups).flat().forEach(element => {
          settings[element] = false;
        });
        return settings;
      }, {});
    }
  },
  methods: {
    loadTeam() {
      axios.get(this.teamUrl).then((response) => {
        this.teamObject = response.data;
        this.teamAutomationSettings = { ...this.emptySettings, ...this.teamObject.teamSettings?.team_automation_settings };
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

