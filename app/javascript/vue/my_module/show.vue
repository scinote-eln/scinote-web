<template>
  <div v-if="myModule">
    <my-module-details :myModule="myModule" @reloadMyModule="fetchMyModule"></my-module-details>
    <my-module-description
      :myModule="myModule"
      @reloadMyModule="fetchMyModule" />
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import MyModuleDescription from './description.vue';
import MyModuleDetails from './details.vue';

export default {
  name: 'MyModuleShow',
  props: {
    myModuleUrl: {
      type: String,
      required: true
    }
  },
  components: {
    MyModuleDescription,
    MyModuleDetails
  },
  data() {
    return {
      myModule: null
    };
  },
  created() {
    this.fetchMyModule();
  },
  methods: {
    fetchMyModule() {
      axios.get(this.myModuleUrl)
        .then(response => {
          this.myModule = response.data.data;
        })
    }
  }
}
</script>
