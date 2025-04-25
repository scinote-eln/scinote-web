<template>
  <div v-if="params.data.comments" class="w-9 flex justify-end">
    <span v-if="!params.data.permissions.create_comments && params.data.comments.count === 0">0</span>
    <a v-else
      href="#"
      class="open-comments-sidebar relative px-1" tabindex=0 :id="'comment-count-' + params.data.id"
      :data-object-type="objectType" :data-object-id="params.data.id">
      <template v-if="params.data.comments.count > 0">
        {{ params.data.comments.count }}
      </template>
      <template v-else>
        +
      </template>
      <span v-if="params.data.comments.count_unseen > 0"
            class="unseen-comments flex align-super text-xs rounded-lg  bg-sn-science-blue
                 text-sn-white h-4 min-w-[1rem] items-center justify-center
                   absolute -top-1.5 left-[100%] px-1">
        {{params.data.comments.count_unseen }}
      </span>
    </a>
</div>
</template>

<script>

export default {
  name: 'CommentsRenderer',
  props: {
    params: {
      required: true
    }
  },
  computed: {
    objectType() {
      switch (this.params.data.type) {
        case 'my_modules':
          return 'MyModule';
        case 'projects':
          return 'Project';
        default:
          return '';
      }
    }
  },
  methods: {
    openModal() {
      this.params.dtComponent.$emit('openComments', null, [this.params.data]);
    }
  }
};
</script>
