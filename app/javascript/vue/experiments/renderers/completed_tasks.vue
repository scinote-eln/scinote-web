<template>
  <div class="relative leading-5 h-full flex items-center">
      <div>
      {{ i18n.t('experiments.card.completed_value', {
        completed: params.data.completed_tasks,
        all: params.data.total_tasks
      }) }}
      <div class="py-1">
        <div class="w-24 h-1 bg-sn-light-grey">
          <div class="h-full bg-sn-blue" :style="{
            width: params.data.completed_tasks / params.data.total_tasks * 100 + '%'
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
};
</script>
