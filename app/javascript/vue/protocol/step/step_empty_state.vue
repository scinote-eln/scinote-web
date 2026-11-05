<template>
  <div class="flex flex-col gap-4" :data-e2e="`e2e-CO-protocol-step${stepId}-emptyState`">
    <template v-if="contentTypes.length">
      <div class="text-base leading-6 font-semibold text-sn-black">{{ i18n.t('protocols.steps.empty.title') }}</div>
      <!-- A grid, not flex: MenuDropdown wraps its button in a div, and flex would size those wrappers differently -->
      <div class="grid gap-2 grid-cols-[repeat(auto-fit,minmax(7.5rem,1fr))]">
        <div v-for="type in contentTypes"
             :key="type.key"
             :data-sn-tooltip="type.disabled ? i18n.t('protocols.action_disabled') : null">
          <MenuDropdown
            v-if="type.submenu && type.submenu.length > 1"
            :listItems="type.submenu"
            :btnText="type.label"
            :btnIcon="`sn-icon ${type.icon}`"
            :btnClasses="tileClasses"
            :disabled="type.disabled"
            :position="'left'"
            :dataE2e="tileE2e(type)"
            @dtEvent="(action, item) => $emit('insert', action, item.params)"
          />
          <button v-else
                  type="button"
                  :class="tileClasses"
                  :disabled="type.disabled"
                  :data-e2e="tileE2e(type)"
                  @click="runDirect(type)">
            <i :class="['sn-icon', type.icon]"></i>
            <span>{{ type.label }}</span>
          </button>
        </div>
      </div>
    </template>
    <div v-else class="text-base leading-6 text-sn-dark-grey" :data-e2e="`e2e-TX-protocol-step${stepId}-noContent`">
      {{ i18n.t('protocols.steps.empty.no_content') }}
    </div>
  </div>
</template>

<script>
import MenuDropdown from '../../shared/menu_dropdown.vue';

export default {
  name: 'StepEmptyState',
  components: { MenuDropdown },
  props: {
    stepId: { type: [String, Number], required: true },
    // From the content_types mixin; only the types this user may insert
    contentTypes: { type: Array, required: true }
  },
  emits: ['insert'],
  computed: {
    tileClasses() {
      return 'w-full h-[88px] p-4 flex flex-col items-center justify-center gap-2 rounded-lg border-0 '
        + 'bg-sn-white text-sn-black text-base leading-6 cursor-pointer hover:bg-sn-light-grey '
        + 'disabled:text-sn-sleepy-grey disabled:cursor-not-allowed disabled:hover:bg-sn-white';
    }
  },
  methods: {
    tileE2e(type) {
      // Insert-menu e2e values are e2e-BT-protocol-step{id}-insertX; tiles use emptyInsertX
      return type.dataE2e.replace('-insert', '-emptyInsert');
    },
    runDirect(type) {
      // A submenu with a single option (usually just "Add file") runs that option directly
      const action = type.submenu ? type.submenu[0] : type;
      this.$emit('insert', action.emit, action.params);
    }
  }
};
</script>
