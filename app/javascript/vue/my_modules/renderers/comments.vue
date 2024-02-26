<template>
  <span v-if="!params.data.permissions.create_comments">0</span>
  <a v-else
     href="#"
     class="open-comments-sidebar" tabindex=0 :id="'comment-count-' + params.data.id"
     data-object-type="MyModule" :data-object-id="params.data.id">
    <template v-if="params.data.comments.count > 0">
      {{ params.data.comments.count }}
    </template>
    <template v-else>
      +
    </template>
    <span v-if="params.data.comments.count_unseen > 0" class="unseen-comments">
      {{params.data.comments.count_unseen }}
    </span>
  </a>
</template>

<script>

export default {
  name: 'CommentsRenderer',
  props: {
    params: {
      required: true
    }
  },
  methods: {
    openModal() {
      this.params.dtComponent.$emit('openComments', null, [this.params.data]);
    }
  }
};
</script>
