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

    if (this.secondaryNavigation) {
      this.resizeObserver = new ResizeObserver((entries) => {
        entries.forEach((entry) => {
          this.taskSecondaryMenuHeight = entry.target.offsetHeight;
        });
      });

      this.resizeObserver.observe(this.secondaryNavigation);
    }
    window.addEventListener('tinyMCEOpened', (e) => {
      this.handleTinyMCEOpened(e.detail.target);
    });
  },
  beforeUnmount() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
    window.removeEventListener('tinyMCEOpened', this.handleTinyMCEOpened);
  },
  methods: {
    handleTinyMCEOpened(target) {
      const getVisibleHeight = (elemTop, elemHeight) => {
        let visibleHeight = 0;
        if (elemTop >= 0) {
          visibleHeight = Math.min(elemHeight, window.innerHeight - elemTop);
        } else if (elemTop + elemHeight > 0) {
          visibleHeight = elemTop + elemHeight;
        }
        return visibleHeight;
      };

      let headerHeight = 0;
      let headerTop = 0;
      let secondaryNavigationHeight = 0;
      let secondaryNavigationTop = 0;

      if (this.headerRef) {
        headerHeight = this.headerRef.offsetHeight;
        headerTop = this.headerRef.getBoundingClientRect().top;
      }

      if (this.secondaryNavigation) {
        secondaryNavigationHeight = this.secondaryNavigation.offsetHeight;
        secondaryNavigationTop = this.secondaryNavigation.getBoundingClientRect().top;
      }

      const editorHeaderTop = target.offset().top;
      let totalHeight = 0;

      const visibleHeaderHeight = getVisibleHeight(headerTop, headerHeight);
      if (headerTop + visibleHeaderHeight < editorHeaderTop) {
        totalHeight += visibleHeaderHeight;
      }

      const visibleSecondaryNavHeight = getVisibleHeight(secondaryNavigationTop, secondaryNavigationHeight);
      if (secondaryNavigationTop + visibleSecondaryNavHeight < editorHeaderTop) {
        totalHeight += visibleSecondaryNavHeight;
      }

      const editorHeader = $('.tox-editor-header');

      // For Protocol Templates
      if (!this.headerRef && !this.secondaryNavigation) {
        if (target[0].getBoundingClientRect().top < 0 && editorHeader.css('position') !== 'fixed') {
          $('html, body').animate({
            scrollTop: target.offset().top - editorHeader.outerHeight(),
          }, 100); // 100ms works best for editorHeader to be fully visible
        } else {
          editorHeader.css('left', '');
        }
        return;
      }

      // Handle opening TinyMCE toolbars when only a small bottom area of editor is visible
      const targetBottom = target[0].getBoundingClientRect().bottom;
      if (targetBottom < 3 * headerHeight) {
        this.$nextTick(() => {
          if (editorHeader.css('position') === 'fixed') {
            editorHeader.css({
              top: totalHeight - 1,
              left: '',
            });
          }
          $('html, body').animate({
            scrollTop: target.offset().top + (visibleHeaderHeight + visibleSecondaryNavHeight),
          }, 100);
        });
        return;
      }

      const headerBottom = this.headerRef.getBoundingClientRect().bottom;
      // Handle showing TinyMCE toolbar for fixed/static position of toolbar
      if (editorHeader.css('position') === 'fixed') {
        editorHeader.css('left', '');
        if (this.headerSticked) {
          editorHeader.css('top', totalHeight - 1);
        }
      } else if (headerTop < (visibleHeaderHeight + visibleSecondaryNavHeight)
        && target[0].getBoundingClientRect().top <= headerBottom) {
        this.$nextTick(() => {
          $('html, body').animate({
            scrollTop: target.offset().top + (visibleHeaderHeight + visibleSecondaryNavHeight),
          }, 100);
        });
      }

      target.focus();
    },
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
        header.style.zIndex = 100;
        this.headerSticked = false;
      }

      // Apply TinyMCE offset
      $('.tox-editor-header').css(
        'top',
        stickyNavigationHeight + parseInt($(this.secondaryNavigation).css('top'), 10) - 1,
      );
      this.lastScrollTop = window.scrollY; // Save last scroll position to when user scroll up/down
    },
  },
};
