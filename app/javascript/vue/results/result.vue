<template>
  <div class="result-wrapper">
    {{ result.id }}
    {{ result.attributes.name }}
    <hr>
  </div>
</template>

<script>
  import Result from './result.vue';

  export default {
    name: 'Results',
    components: { Result },
    props: {
      result: { type: Object, required: true }
    }
  }
</script>
