<template>
  <div ref="itemRelationshipsModal" @keydown.esc="cancel" id="itemRelationshipsModal" tabindex="-1" role="dialog"
    class="modal">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content">

        <!-- header -->
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span
              aria-hidden="true">&times;</span></button>
          <h4 class="modal-title" id="modal-destroy-team-label">
            {{ rowCode }}
          </h4>
        </div>
        <div v-if="isLoading" class="flex justify-center h-40 w-auto">
          <p class="m-auto h-fit w-fit">Loading...</p>
        </div>
        <div v-else class="modal-body ">

          <!-- parents -->
          <div v-if="parents?.length > 0">
            <p>Parents:</p>
            <div v-for="(parentObj, index) in parents" :key="index" class="flex flex-col">
              <div>{{ parentObj?.code }} | {{ parentObj?.name }}</div>
            </div>
          </div>

          <!-- children -->
          <div v-if="children?.length > 0">
            <p>Children:</p>
            <div v-for="(childObj, index) in children" :key="index" class="flex flex-col">
              <div>{{ childObj?.code }} | {{ childObj?.name }}</div>
            </div>
          </div>
        </div>

        <!-- footer -->
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancel">{{ i18n.t('general.cancel') }}</button>
        </div>

      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ItemRelationshipsModal',
  created() {
    window.itemRelationshipsModal = this;
  },
  data() {
    return {
      isLoading: false,
      rowCode: null,
      parents: [],
      children: []
    };
  },
  methods: {
    show(relationshipsUrl) {
      $(this.$refs.itemRelationshipsModal).modal('show');
      this.fetchItemRelationshipsData(relationshipsUrl);
    },
    fetchItemRelationshipsData(relationshipsUrl) {
      this.isLoading = true;
      $.ajax({
        method: 'GET',
        url: relationshipsUrl,
        dataType: 'json',
        success: (result) => {
          this.isLoading = false;
          this.parents = result.parents;
          this.children = result.children;
          this.rowCode = result.repository_row.code;
        }
      });
    },
    cancel() {
      $(this.$refs.itemRelationshipsModal).modal('hide');
    }
  }
};
</script>
