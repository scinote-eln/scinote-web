<template>
  <div class="bg-white rounded py-10 flex justify-center min-h-[70vh]">
    <div class="max-w-[800px] w-full rounded bg-sn-super-light-grey p-6 flex flex-col gap-4">
      <h3 class="my-1">{{ form.attributes.name }}</h3>
      <Field v-for="field in fields" :key="field.id" :field="field" />
    </div>
  </div>
</template>

<script>
import Field from './field.vue';

export default {
  name: 'Preview',
  props: {
    form: Object,
    fields: Array
  },
  components: {
    Field
  }
};
</script>
