import axios from '../../packs/custom_axios.js';

export default {
  watch: {
    visible(newValue) {
      if (newValue) {
        [this.defaultRole] = this.userRoles.find((role) => role[1] === 'Viewer');
      } else {
        this.defaultRole = null;
      }
    }
  },
  mounted() {
    this.fetchUserRoles();
  },
  data() {
    return {
      visible: false,
      defaultRole: null,
      userRoles: [],
    }
  },
  methods: {
    changeRole(role) {
      this.defaultRole = role;
    },
    fetchUserRoles() {
      axios.get(this.userRolesUrl())
        .then((response) => {
          this.userRoles = response.data.data;
        });
    },
  }
};
