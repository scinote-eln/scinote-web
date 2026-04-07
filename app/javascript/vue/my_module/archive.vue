<template>
  <div class="mt-4">
    <div class="mt-4">
      <ArchiveResults v-if="activeMode=== 'results'" :myModuleId="myModuleId" @update:mode="setActiveMode" />
      <ArchiveSteps v-if="activeMode === 'steps'" :protocolId="protocolId" @update:mode="setActiveMode"/>
    </div>
  </div>
</template>

<script>
import ArchiveResults from './archive_results.vue';
import ArchiveSteps from './archive_steps.vue';

const SORTS = [
  'updated_at_asc',
  'updated_at_desc',
  'created_at_asc',
  'created_at_desc',
  'name_asc',
  'name_desc'
];

export default {
  props: {
    myModuleId: {
      required: true
    },
    protocolId: {
      required: true
    },
    initialMode: {
      type: String,
      default: 'steps'
    }
  },
  data() {
    return {
      activeMode: this.initialMode
    };
  },
  components: {
    ArchiveResults,
    ArchiveSteps
  },
  methods: {
    setActiveMode(mode) {
      this.activeMode = mode;
    }
  }
}
</script>
