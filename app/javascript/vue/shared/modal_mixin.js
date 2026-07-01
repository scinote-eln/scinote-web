export default {
  mounted() {
    if (this.sciModal) {
      this.open();
      this.$refs.modal.addEventListener('click', (event) => {
        if (event.target === this.$refs.modal) {
          this.close();
        }
      });
    } else {
      if (!this.startHidden) {
        $(this.$refs.modal).modal('show');
      }
      this.$refs.input?.focus();
      $(this.$refs.modal).on('hidden.bs.modal', () => {
        this.$emit('close');
      });
    }
  },
  data() {
    return {
       modalBackdrop: null,
    };
  },
  computed: {
    modalLevels() {
      return {
        'low': 1900,
        'main': 2000,
        'high': 2100,
      }
    }
  },
  beforeUnmount() {
    if (this.sciModal) {
      this.close();
    } else {
      $(this.$refs.modal).modal('hide');
    }
  },
  methods: {
    close() {
      if (this.sciModal) {
        if (document.querySelectorAll('.sci-modal').length === 1) {
          document.querySelector('body').classList.remove('modal-open');
        }
        this.removeModalBackdrop();
        this.$emit('close');
      } else {
        this.$emit('close');
        $(this.$refs.modal).modal('hide');
      }
    },
    open() {
      if (this.sciModal) {
        this.$refs.modal.style.zIndex = this.modalLevels[this.modalLevel] || this.modalLevels['main'];
        this.$refs.modal.style.display = 'block';
        this.$refs.modal.classList.add('sci-modal');
        this.addModalBackdrop();
        document.querySelector('body').classList.add('modal-open');
        this.$emit('open');
      } else {
        this.$emit('open');
        $(this.$refs.modal).modal('show');
      }
    },
    addModalBackdrop() {
      if (this.sciModal) {
        const backdrop = document.createElement('div');
        backdrop.classList.add('sci-modal-backdrop', 'fade', 'in');
        backdrop.style.zIndex = (this.modalLevels[this.modalLevel] || this.modalLevels['main']) - 1;
        document.body.appendChild(backdrop);
        this.modalBackdrop = backdrop;
      }
    },
    removeModalBackdrop() {
      if (this.sciModal && this.modalBackdrop) {
        document.body.removeChild(this.modalBackdrop);
        this.modalBackdrop = null;
      }
    }
  }
};
