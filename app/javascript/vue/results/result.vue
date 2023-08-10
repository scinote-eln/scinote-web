<template>
  <div class="result-wrapper" :class="{ 'showing-comments': showCommentsSidebar }">
    {{ result.id }}
    {{ result.attributes.name }}
    <a href="#"
       ref="comments"
       class="open-comments-sidebar btn icon-btn btn-light btn-black"
       data-turbolinks="false"
       data-object-type="Result"
       @click="openCommentsSidebar"
       :data-object-id="result.id">
       <i class="sn-icon sn-icon-comments"></i>
    </a>
    <hr>
  </div>
</template>

<script>
  export default {
    name: 'Result',
    props: {
      result: { type: Object, required: true }
    },
    data() {
      return {
        showCommentsSidebar: false
      }
    },
    mounted() {
      $(this.$refs.comments).data('closeCallback', this.closeCommentsSidebar);
      $(this.$refs.comments).data('openCallback', this.closeCommentsSidebar);
    },
    methods: {
      openCommentsSidebar() {
        $('.comments-sidebar .close-btn').click();
        this.showCommentsSidebar = true
      },
      closeCommentsSidebar() {
        this.showCommentsSidebar = false
      }
    }
  }
</script>
