<template>
  <a :href="params.data.urls.results" >{{ params.data.results }}</a>
</template>

<script>
export default {
  name: 'ResultsRenderer',
  props: {
    params: {
      required: true
    }
  }
};
</script>
