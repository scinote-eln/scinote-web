/*
 * Mixin for adjusting stackable headers on scroll.
 * - Tracks scroll position to modify headers' styles & positions.
 * - Observes changes in the secondary navigation's height.
 * - Adjusts TinyMCE editor header offset if present.
 */

export default {
  data() {
    return {
      lastScrollTop: 0,
      headerSticked: false,
      secondaryNavigation: null,
      taskSecondaryMenuHeight: 0,
    };
  },
  computed: {
    headerRef() {
      return this.getHeader();
    },
  },
  mounted() {
    this.secondaryNavigation = document.querySelector('#taskSecondaryMenu');

    this.resizeObserver = new ResizeObserver((entries) => {
      entries.forEach((entry) => {
        this.taskSecondaryMenuHeight = entry.target.offsetHeight;
      });
    });

    this.resizeObserver.observe(this.secondaryNavigation);
  },
  beforeDestroy() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
  },
  methods: {
    initStackableHeaders() {
      const header = this.headerRef;
      const headerHeight = header.offsetHeight;
      const headerTop = header.getBoundingClientRect().top;
      const secondaryNavigationTop = this.secondaryNavigation.getBoundingClientRect().top;

      // TinyMCE offset calculation
      let stickyNavigationHeight = this.taskSecondaryMenuHeight;
      if ($('.tox-editor-header').length > 0 && $('.tox-editor-header')[0].getBoundingClientRect().top > headerTop) {
        stickyNavigationHeight += headerHeight;
      }

      // Add shadow to secondary navigation when it starts fly
      if (this.secondaryNavigation.getBoundingClientRect().top === 0 && !this.headerSticked) {
        this.secondaryNavigation.style.boxShadow = '0 9px 8px -2px rgba(0, 0, 0, 0.1)';
        this.secondaryNavigation.style.zIndex = 252;
      } else {
        this.secondaryNavigation.style.boxShadow = 'none';
        if (secondaryNavigationTop > 10) this.secondaryNavigation.style.zIndex = 11;
      }

      if (headerTop - 5 < this.taskSecondaryMenuHeight) { // When secondary navigation touch header
        this.secondaryNavigation.style.top = `${headerTop - headerHeight}px`; // Secondary navigation starts slowly disappear
        header.style.boxShadow = '0 9px 8px -2px rgba(0, 0, 0, 0.1)'; // Flying shadow
        header.style.zIndex = 250;

        this.headerSticked = true;


        if (this.lastScrollTop > window.scrollY) { // When user scroll up
          let newSecondaryTop = secondaryNavigationTop - (window.scrollY - this.lastScrollTop); // Calculate new top position of secondary navigation
          if (newSecondaryTop > 0) newSecondaryTop = 0;

          this.secondaryNavigation.style.top = `${newSecondaryTop}px`; // Secondary navigation starts slowly appear
          this.secondaryNavigation.style.zIndex = 252;
          header.style.top = `${this.taskSecondaryMenuHeight + newSecondaryTop - 1}px`; // Header starts getting offset to compensate secondary navigation position
          // -1 to compensate small gap between header and secondary navigation
        } else { // When user scroll down
          let newSecondaryTop = secondaryNavigationTop - (window.scrollY - this.lastScrollTop); // Calculate new top position of secondary navigation
          if (newSecondaryTop * -1 > this.taskSecondaryMenuHeight) newSecondaryTop = this.taskSecondaryMenuHeight * -1;

          this.secondaryNavigation.style.top = `${newSecondaryTop}px`; // Secondary navigation starts slowly disappear
          header.style.top = `${newSecondaryTop + this.taskSecondaryMenuHeight - 1}px`; // Header starts getting offset to compensate secondary navigation position
          // -1 to compensate small gap between header and secondary navigation
          if (newSecondaryTop * -1 >= this.taskSecondaryMenuHeight) this.secondaryNavigation.style.zIndex = 11;
        }
      } else {
        // Just reset secondary navigation and header styles to initial state
        this.secondaryNavigation.style.top = '0px';
        header.style.top = '0px';
        header.style.boxShadow = 'none';
        header.style.zIndex = 10;
        this.headerSticked = false;
      }

      // Apply TinyMCE offset
      $('.tox-editor-header').css(
        'top',
        stickyNavigationHeight + parseInt($(this.secondaryNavigation).css('top'), 10)
      );

      this.lastScrollTop = window.scrollY; // Save last scroll position to when user scroll up/down
    },
  },
};
