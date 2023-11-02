<template>
  <div class="flex gap-3">
    <div id="navigation-text"
      class="flex flex-col py-2 px-0 gap-3 self-stretch w-[130px] h-[130px] justify-center items-center">
      <div v-for="navigationItem in itemsToCreate" :key="navigationItem.textId" @click="navigateToSection(navigationItem)"
        class="nav-text-item flex flex-col w-[130px] h-[130px] justify-between text-right hover:cursor-pointer"
        :class="{ 'text-sn-science-blue': selectedNavText === navigationItem.textId, 'text-sn-grey': selectedNavText !== navigationItem.textId }">
        {{ i18n.t(`repositories.highlight_component.${navigationItem.labelAlias}`) }}
      </div>
    </div>

    <div id="highlight-container" class="w-[1px] h-[130px] flex flex-col justify-evenly bg-sn-light-grey">
      <div v-for="navigationItem in itemsToCreate" :key="navigationItem.id" class="w-[5px] h-[28px] rounded-[11px]"
        :class="{ 'bg-sn-science-blue relative left-[-2px]': selectedNavIndicator === navigationItem.id }"></div>
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
      activeSection: null,
      proximityThreshold: 60,
      header: null,
      previousScrollTop: 0,
    };
  },

  computed: {
    headerHeight() {
      return this.header.getBoundingClientRect().height;
    }
  },

  mounted() {
    this.initializeComponent();
  },

  beforeDestroy() {
    this.removeScrollListener();
  },

  watch: {
    activeSection: 'highlightSection'
  },

  methods: {
    initializeComponent() {
      this.header = this.$parent.$refs.stickyHeaderRef;
      this.bodyContainerEl = this.$parent.$refs.bodyWrapper;
      this.sections = Array.from(this.$parent.$refs.scrollSpyContent.querySelectorAll('section[id]'));
      this.proximityThreshold = this.headerHeight;
      this.highlightSection(this.sections[0]);
      this.addScrollListener();
    },

    addScrollListener() {
      this.bodyContainerEl?.addEventListener('scroll', this.handleScroll);
    },

    removeScrollListener() {
      this.bodyContainerEl?.removeEventListener('scroll', this.handleScroll);
    },

    handleScroll() {
      const currentScrollTop = this.bodyContainerEl.scrollTop;

      if (currentScrollTop === 0) {
        this.setActiveSection(this.sections[0]);
        return;
      }

      // Determine the scroll direction (down or up)
      if (currentScrollTop > this.previousScrollTop) {
        this.handleScrollDown();
      } else {
        this.handleScrollUp();
      }

      this.previousScrollTop = currentScrollTop;
    },

    // scrolling from up -> down
    // highlighting based on proximity to the header
    handleScrollDown() {
      const headerTop = this.getDistanceToTop(this.header);
      const nearestSection = this.sections.reduce((acc, section) => {
        const distance = Math.abs(headerTop - this.getDistanceToTop(section));
        return distance < this.proximityThreshold ? section : acc;
      }, null);

      if (nearestSection) this.setActiveSection(nearestSection);
    },

    // scrolling from down -> up
    // highlighting based on passing out of view
    handleScrollUp() {
      if (!this.activeSection) return;

      const activeSectionRect = this.activeSection.getBoundingClientRect();
      const containerRect = this.bodyContainerEl.getBoundingClientRect();

      if (activeSectionRect.bottom < containerRect.top || activeSectionRect.top > containerRect.bottom) {
        const previousSection = this.getPreviousSection(this.activeSection);
        if (previousSection) this.setActiveSection(previousSection);
      }
    },

    getPreviousSection(currentSection) {
      const index = this.sections.indexOf(currentSection);
      return index > 0 ? this.sections[index - 1] : null;
    },

    getDistanceToTop(el) {
      return el.getBoundingClientRect().top;
    },

    setActiveSection(section) {
      if (section !== this.activeSection) {
        this.activeSection = section;
        this.highlightSection(section);
      }
    },

    highlightSection(section) {
      const foundObj = this.itemsToCreate.find(obj => obj.sectionId === section.id);
      if (foundObj) {
        this.selectedNavText = foundObj.textId;
        this.selectedNavIndicator = foundObj.id;
      }
    },

    navigateToSection(navigationItem) {
      if (!this.bodyContainerEl) return;

      this.removeScrollListener();
      this.activeSection = document.getElementById(navigationItem.sectionId);
      this.selectedNavText = navigationItem.textId;
      this.selectedNavIndicator = navigationItem.id;

      const domElToScrollTo = this.$parent.$refs[navigationItem.label];
      const top = domElToScrollTo.offsetTop - (this.stickyHeaderHeightPx + this.cardTopPaddingPx);

      this.bodyContainerEl.scrollTo({
        top,
        behavior: "auto"
      });

      this.flashTitleColor(domElToScrollTo);
      setTimeout(this.addScrollListener, 100);
    },

    flashTitleColor(domEl) {
      if (!domEl) return

      domEl.classList.add('text-sn-science-blue');
      setTimeout(() => domEl.classList.remove('text-sn-science-blue'), 300);
    },
  }
}
</script>
