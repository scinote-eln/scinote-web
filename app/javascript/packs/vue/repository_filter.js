import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import FilterContainer from '../../vue/repository_filter/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initRepositoryFilter = () => {
  const repositoryFilterContainer = new Vue({
    el: '#filterContainer',
    data: () => {
      return {
        filters: [],
        columns: []
      };
    },
    created() {
      this.dataTableElement = $($('#filterContainer').data('datatable-id'));
    },
    components: {
      'filter-container': FilterContainer
    },
    methods: {
    }
  });

  // Replace with remote endpoint
  repositoryFilterContainer.columns = [
    {id: 'row_name', name: 'Column 1', colType: 'TextColumn'},
    {id: 1, name: 'Column 2', colType: 'TextColumn'},
    {id: 2, name: 'Column 3', colType: 'NumberColumn'},
    {id: 3, name: 'Column 4', colType: 'TextColumn'}
  ]
  $('#filterContainer').on('click', (e) => e.stopPropagation());

};
