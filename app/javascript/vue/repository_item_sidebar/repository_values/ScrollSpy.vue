<template>
  <div class="flex gap-3">
    <div id="navigation-text"
      class="flex flex-col py-2 px-0 gap-3 self-stretch w-[130px] h-[130px] justify-center items-center">
      <div v-for="(navigationItem, index) in itemsToCreate" :key="navigationItem.textId"
        @click="navigateToSection(navigationItem)"
        class="text-sn-grey nav-text-item flex flex-col w-[130px] h-[130px] justify-between text-right hover:cursor-pointer"
        :class="{ 'text-sn-science-blue': (arrOfThresholds[index]?.from <= scrollPosition && scrollPosition <= arrOfThresholds[index]?.to) }">
        {{ i18n.t(`repositories.highlight_component.${navigationItem.labelAlias}`) }}
      </div>
    </div>

    <div id="highlight-container" class="w-[1px] h-[130px] flex flex-col justify-evenly bg-sn-light-grey">
      <div v-for="(navigationItem, index) in itemsToCreate" :key="navigationItem.id"
        class="w-[5px] h-[28px] rounded-[11px]"
        :class="{ 'bg-sn-science-blue relative left-[-2px]': (arrOfThresholds[index]?.from <= scrollPosition && scrollPosition <= arrOfThresholds[index]?.to) }">
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ScrollSpy',

  props: {
    itemsToCreate: Array,
  },

  data() {
    return {
      bodyContainerEl: null,
      sections: [],
      sectionsWithHeight: [],
      allSectionsCumulativeHeight: null,
      arrOfThresholds: [],
      scrollPosition: null,
      centerOfScrollThumb: null,
    };
  },

  mounted() {
    this.initializeComponent();
    this.$nextTick(() => {
      this.calculateAllSectionsCumulativeHeight()
      this.calculateSectionsHeight();
      this.constructThresholds()
    });
  },

  beforeDestroy() {
    this.removeScrollListener();
  },

  methods: {
    initializeComponent() {
      const bodyWrapperEl = document.getElementById('body-wrapper')
      const scrollSpyContentEl = document.getElementById('scrollSpyContent')
      this.bodyContainerEl = bodyWrapperEl
      this.sections = Array.from(scrollSpyContentEl.querySelectorAll('section[id]'));
      this.addScrollListener();
    },

    addScrollListener() {
      this.bodyContainerEl?.addEventListener('scroll', this.handleScroll);
    },

    removeScrollListener() {
      this.bodyContainerEl?.removeEventListener('scroll', this.handleScroll);
    },

    calculateAllSectionsCumulativeHeight() {
      let totalHeight = 0

      this.itemsToCreate.forEach((item) => {
        const sectionEl = document.getElementById(item.sectionId);
        totalHeight += sectionEl.offsetHeight
      })
      this.allSectionsCumulativeHeight = totalHeight
    },

    calculateSectionsHeight() {
      // Initialize an array to store the height data for each section
      this.sectionsWithHeight = this.itemsToCreate.map(item => {
        // Find the DOM element for the section
        const sectionEl = document.getElementById(item.sectionId);

        // Calculate the height of the section as a percentage of the total scrollable height
        const heightPx = sectionEl.offsetHeight;
        const percentHeight = Math.round((heightPx / this.allSectionsCumulativeHeight) * 100);

        // Return an object containing the section ID and its percentage height
        return {
          sectionId: item.sectionId,
          heightPx: heightPx,
          percentHeight: percentHeight
        };
      });
    },

    // Constructs and populates array of thresholds with threshold objects.
    // Each object stores id, index, and threshold values (from/to) for a section, based
    // on the % of vertical space of scrollable content that they occupy
    constructThresholds() {
      const scrollableArea = this.bodyContainerEl;
      const deltaTravel = scrollableArea.scrollHeight - scrollableArea.clientHeight
      const viewportHeight = scrollableArea.clientHeight;
      const scrollableAreaHeight = scrollableArea.scrollHeight;
      const scrollThumbHeight = Math.round(viewportHeight / scrollableAreaHeight * viewportHeight);
      const scrollThumbCenter = Math.round(scrollThumbHeight / 2)
      this.centerOfScrollThumb = scrollThumbCenter
      this.scrollPosition = scrollThumbCenter

      let prevThreshold = scrollThumbCenter

      for (let i = 0; i < this.sectionsWithHeight.length; i++) {
        // first section
        if (i === 0) {
          const from = prevThreshold
          const to = Math.round(deltaTravel * this.sectionsWithHeight[i].percentHeight / 100) + prevThreshold
          const id = this.sectionsWithHeight[i].sectionId
          prevThreshold = to + 1
          const thresholdObj = {
            id,
            index: i,
            from,
            to
          }
          this.arrOfThresholds[i] = thresholdObj
        }
        // last section
        else if (i === this.sectionsWithHeight.length - 1) {
          const from = prevThreshold
          const to = scrollableArea.scrollHeight
          const id = this.sectionsWithHeight[i].sectionId
          const thresholdObj = {
            id,
            index: i,
            from,
            to
          }
          this.arrOfThresholds[i] = thresholdObj
        }
        else {
          // other sections
          const from = prevThreshold
          const to = Math.round(deltaTravel * this.sectionsWithHeight[i].percentHeight / 100) + prevThreshold - 1
          const id = this.sectionsWithHeight[i].sectionId
          prevThreshold = to + 1
          const thresholdObj = {
            id,
            index: i,
            from,
            to
          }
          this.arrOfThresholds[i] = thresholdObj
        }
      }
    },

    // Handling scroll event
    handleScroll() {
      const scrollableArea = this.bodyContainerEl;
      const scrollThumbsDistanceFromTop = scrollableArea.scrollTop + this.centerOfScrollThumb;
      this.scrollPosition = scrollThumbsDistanceFromTop
    },

    // Navigating (scrolling into view) via click
    navigateToSection(navigationItem) {
      if (!this.bodyContainerEl) return;

      const scrollableArea = this.bodyContainerEl;
      const foundObj = this.arrOfThresholds.find((obj) => obj.id === navigationItem.sectionId)
      const domElToScrollTo = document.getElementById(navigationItem.label)

      if (foundObj.index === 0) {
        // scroll to top
        this.bodyContainerEl.scrollTo({
          top: 0,
          behavior: "auto"
        });
      }
      else if (foundObj.index === this.arrOfThresholds.length - 1) {
        // scroll to bottom
        this.bodyContainerEl.scrollTo({
          top: 99999,
          behavior: "auto"
        });
      }
      else {
        // scroll to the start of a section's threshold, adjusted for the center thumb value (true center)
        scrollableArea.scrollTop = foundObj.from - this.centerOfScrollThumb
      }
      this.flashTitleColor(domElToScrollTo);
    },

    flashTitleColor(domEl) {
      if (!domEl) return

      domEl.classList.add('text-sn-science-blue');
      setTimeout(() => domEl.classList.remove('text-sn-science-blue'), 300);
    },
  }
}
</script>
