import axios from '../../packs/custom_axios.js';

export default {
  mounted() {
    const img = this.params.data ? this.params.data.workflow_img : this.params.workflow_img;
    if (img) {
      this.workflow_img = img;
    } else {
      this.loadExprimentWorflowImage();
    }
  },
  data() {
    return {
      workflow_img: null,
      imageLoading: false,
      hasError: false
    };
  },
  methods: {
    loadExprimentWorflowImage() {
      const url = this.params.data ? this.params.data.urls.workflow_img : this.params.urls.workflow_img;
      this.imageLoading = true;
      axios.get(url)
        .then((response) => {
          this.workflow_img = response.data.workflowimg_url;
          this.imageLoading = false;
        });
    }
  }
};
