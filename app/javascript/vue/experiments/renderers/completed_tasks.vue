<template>
  <div class="relative leading-5 h-full flex items-center">
    <div>
      {{ i18n.t('experiments.card.completed_value', {
        completed: params.data.completed_tasks,
        all: params.data.total_tasks
      }) }}
      <div class="py-1">
        <div class="w-24 h-1 bg-sn-light-grey">
          <div class="h-full"
               :class="{
                 'bg-sn-black': params.data.archived_on,
                 'bg-sn-blue': !params.data.archived_on
               }"
               :style="{
                 width: `${progress}%`
               }"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CompletedTasksRenderer',
  props: {
    params: {
      required: true,
    },
  },
  computed: {
    progress() {
      const { completed_tasks: completedTasks, total_tasks: totalTasks } = this.params.data;

      if (totalTasks === 0) return 0;

      return (completedTasks / totalTasks) * 100;
    }
  }
};
</script>
