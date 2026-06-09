<template>
  <div v-if="myModule">
    <div v-if="myModule.attributes.read_only_description" class="bg-white px-4 my-4 task-section">
      <div class="py-4" v-html="myModule.attributes.read_only_description"></div>
    </div>
    <my-module-details :myModule="myModule" :detailsKey="detailsKey" @reloadMyModule="fetchMyModule" @reloadSubject="fetchMyModule"></my-module-details>
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
      myModule: null,
      detailsKey: 0
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
          this.detailsKey += 1;
        })
    }
  }
}
</script>
