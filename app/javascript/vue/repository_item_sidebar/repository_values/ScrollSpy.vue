<template>
  <!-- This will be re-implemented using vue2-scrollspy library in a following ticket -->
  <div class="flex gap-3">
    <div id="navigation-text">
      <div class="flex flex-col py-2 px-0 gap-3 self-stretch w-[130px] h-[130px]  justify-center items-center">
        <div v-for="(itemObj, index) in itemsToCreate" :key="index"
          class="flex flex-col w-[130px] h-[130px] justify-between text-right">
          <div @click="handleSideNavClick" :id="itemObj?.textId" class="hover:cursor-pointer text-sn-grey"
            :class="{ 'text-sn-science-blue': selectedNavText === itemObj?.textId }">{{
              i18n.t(`repositories.highlight_component.${itemObj?.labelAlias}`) }}
          </div>
        </div>
      </div>
    </div>
    <div id="highlight-container" class="w-[1px] h-[130px] flex flex-col justify-evenly bg-sn-light-grey">
      <div v-for="(itemObj, index) in itemsToCreate" :key="index">
        <div :id="itemObj.id" class="w-[5px] h-[28px] rounded-[11px]"
          :class="{ 'bg-sn-science-blue relative left-[-2px]': itemObj.id === selectedNavIndicator }"></div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ScrollSpy',
  props: {
    itemsToCreate: Array,
    stickyHeaderHeightPx: Number || null,
    cardTopPaddingPx: Number || null
  },
  data() {
    return {
      rootContainerEl: null,
      selectedNavText: null,
      selectedNavIndicator: null,
      positions: []
    }
  },
  created() {
    this.rootContainerEl = this.$parent.$refs.wrapper
    this.rootContainerEl?.addEventListener('scroll', this.handleScrollBehaviour)
  },

  methods: {
    handleScrollBehaviour() {
      // used for keeping scroll spy sticky
      this.updateNavigationPositionOnScroll()
    },
    updateNavigationPositionOnScroll() {
      const navigationDom = this?.$parent?.$refs?.navigationRef
      // Get the current scroll position
      const scrollPosition = this?.rootContainerEl?.scrollTop
      // Adjust navigationDom position equal to the scrollPosition + the header height and the card top padding (if present)
      navigationDom.style.top = `${scrollPosition + this?.stickyHeaderHeightPx + this?.cardTopPaddingPx}px`;
    },

    handleSideNavClick(e) {
      if (!this.rootContainerEl) {
        return
      }
      let refToScrollTo
      const targetId = e.target.id

      const foundObj = this.itemsToCreate.find((obj) => obj.textId === targetId)
      if (!foundObj) return

      refToScrollTo = foundObj.label
      this.selectedNavText = foundObj.textId
      this.selectedNavIndicator = foundObj.id
      const sectionLabels = this.itemsToCreate.map((obj) => obj.label)
      const labelsToUnhighlight = sectionLabels.filter((i) => i !== refToScrollTo)

      // scrolling to desired section
      const domElToScrollTo = this.$parent.$refs[refToScrollTo]
      this.rootContainerEl.scrollTo({
        top: domElToScrollTo.offsetTop - this?.stickyHeaderHeightPx - this?.cardTopPaddingPx,
        behavior: "auto"
      })

      // flashing the title color to blue and back over 300ms
      const timeoutId = setTimeout(() => {
        // wrapped in timeout to ensure that the color-change animation happens after the scrolling animation is completed
        domElToScrollTo?.classList.add('text-sn-science-blue')
        labelsToUnhighlight.forEach(id => document.getElementById(id)?.classList.remove('text-sn-science-blue'))
        setTimeout(() => {
          domElToScrollTo?.classList.remove('text-sn-science-blue')
        }, 400)
        clearTimeout(timeoutId)
      }, 500)
    }
  },
}
</script>
