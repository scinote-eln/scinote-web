<template>
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
        <div :id="itemObj?.id" class="w-[5px] h-[28px] rounded-[11px]"
          :class="{ 'bg-sn-science-blue relative left-[-2px]': itemObj?.id === selectedNavIndicator }"></div>
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
    cardTopPaddingPx: Number || null,
    targetAreaMargin: Number || null
  },
  data() {
    return {
      bodyContainerEl: null,
      selectedNavText: null,
      selectedNavIndicator: null,
      sections: [],
      prevSection: null,
      scrollTimer: null,
      shouldRecalculateWhenStopped: false
    }
  },
  mounted() {
    this.bodyContainerEl = this.$parent.$refs.bodyWrapper
    this.sections = this.$parent.$refs.scrollSpyContent.querySelectorAll('section[id]');
    this.bodyContainerEl?.addEventListener('scroll', this.handleScroll)
    this.highlightActiveSectionOnScroll()
  },
  methods: {
    // If the user scrolls too fast to register movement, then we need to do something when the scrolling has stopped.
    // When the scrolling has stopped and if we have permission to recalculate
    // then we find the closest dom node relative to the target area and highlight it
    scrollStopped() {
      if (!this.shouldRecalculateWhenStopped) return

      const bodyWrapperTargetAreaRectTop = this.bodyContainerEl.getBoundingClientRect().top;
      const sectionRects = Array.from(this.sections).map((s) => {
        const rect = s.getBoundingClientRect();
        return {
          top: rect.top,
          right: rect.right,
          bottom: rect.bottom,
          left: rect.left,
          width: rect.width,
          height: rect.height,
          id: s.getAttribute('id'),
        };
      });

      const closestDomNodeToHighlight = this.findClosestDomNode(sectionRects, bodyWrapperTargetAreaRectTop)

      // If user clicked on the navigation and not actually scrolled the scroll event still happened.
      // However, in those cases top/bot values will be zero and we should not compute closestDomNode highlighting
      if (closestDomNodeToHighlight.top !== 0 && closestDomNodeToHighlight.bottom !== 0) {
        const id = closestDomNodeToHighlight.id
        const foundMatchToHighlight = this.itemsToCreate.find((e) => e.sectionId === id)
        this.selectedNavText = foundMatchToHighlight.textId
        this.selectedNavIndicator = foundMatchToHighlight.id
      }
    },

    // For finding the closest dom node (to highlight)
    findClosestDomNode(arr, referenceValue) {
      if (arr.length === 0) {
        return null;
      }
      let closestObject = arr[0];
      let minDifference = Math.abs(arr[0].top - referenceValue);
      for (let i = 1; i < arr.length; i++) {
        const difference = Math.abs(arr[i].top - referenceValue);
        if (difference < minDifference) {
          minDifference = difference;
          closestObject = arr[i];
        }
      }
      return closestObject;
    },

    // Handling scroll events
    handleScroll() {
      this.shouldRecalculateWhenStopped = true
      this.highlightActiveSectionOnScroll()
      if (this.scrollTimer) {
        clearTimeout(this.scrollTimer);
      }
      this.scrollTimer = setTimeout(this.scrollStopped, 200);
    },

    // Highlighting active sections while scrolling
    highlightActiveSectionOnScroll() {
      if (!this.bodyContainerEl) return;

      const bodyWrapperTargetAreaRect = this.bodyContainerEl.getBoundingClientRect();
      const margin = this.targetAreaMargin;

      // Far top position
      if (this.bodyContainerEl.scrollTop === 0) {
        this.shouldRecalculateWhenStopped = false
        this.handleTopOrBotScrollPosition(this.sections[0]);
        return;
      }

      // Far bottom position
      if (this.bodyContainerEl.scrollTop + this.bodyContainerEl.clientHeight === this.bodyContainerEl.scrollHeight) {
        this.shouldRecalculateWhenStopped = false
        this.handleTopOrBotScrollPosition(this.sections[this.sections.length - 1])
        return
      }

      // Checks when a section enters targetArea's boundary and highlights it
      for (const section of this.sections) {
        const sectionRect = section.getBoundingClientRect();
        if (sectionRect === this.prevSection) continue;

        if (this.isSectionInBounds(sectionRect, bodyWrapperTargetAreaRect, margin)) {
          this.handleSectionHighlight(section);
        }
      }
    },

    // For handling top/bottom most positions
    handleTopOrBotScrollPosition(section) {
      const sectionId = section.getAttribute('id');
      const foundObj = this.itemsToCreate.find((obj) => obj?.sectionId === sectionId);

      if (foundObj) {
        this.selectedNavText = foundObj.textId;
        this.selectedNavIndicator = foundObj.id;
      }
    },

    // For checking if a section is within targetArea's boundaries
    isSectionInBounds(sectionRect, targetAreaRect, margin) {
      const upperBound = targetAreaRect.top - margin;
      const lowerBound = targetAreaRect.top + margin;
      return sectionRect.top >= upperBound && sectionRect.top <= lowerBound;
    },

    // For highlighting a section during scrolling
    handleSectionHighlight(section) {
      const sectionId = section.getAttribute('id');
      const foundObj = this.itemsToCreate.find((obj) => obj?.sectionId === sectionId);

      if (foundObj) {
        this.selectedNavText = foundObj.textId;
        this.selectedNavIndicator = foundObj.id;
        this.prevSection = section.getBoundingClientRect();
      }
    },

    // For handling clicks on the side navigation
    handleSideNavClick(e) {
      if (!this.bodyContainerEl) return
      this.bodyContainerEl?.removeEventListener('scroll', this.handleScroll)

      let refToScrollTo
      const targetId = e.target.id
      const foundObj = this.itemsToCreate.find((obj) => obj?.textId === targetId)
      if (!foundObj) return

      // Highlighting
      refToScrollTo = foundObj.label
      this.selectedNavText = foundObj.textId
      this.selectedNavIndicator = foundObj.id
      const sectionLabels = this.itemsToCreate.map((obj) => obj.label)
      const labelsToUnhighlight = sectionLabels.filter((i) => i !== refToScrollTo)

      // Scrolling to desired section
      const domElToScrollTo = this.$parent.$refs[refToScrollTo]
      const top = domElToScrollTo.offsetTop - this?.stickyHeaderHeightPx - this?.cardTopPaddingPx;
      this.bodyContainerEl.scrollTo({
        top: top,
        behavior: "auto"
      })

      // flashing the title color to blue and back over 300ms
      domElToScrollTo?.classList.add('text-sn-science-blue')
      labelsToUnhighlight.forEach(id => document.getElementById(id)?.classList.remove('text-sn-science-blue'))
      setTimeout(() => {
        domElToScrollTo?.classList.remove('text-sn-science-blue')
      }, 300)

      setTimeout(() => {
        this.bodyContainerEl?.addEventListener('scroll', this.handleScroll)
      }, 100)

    }
  },
}
</script>
