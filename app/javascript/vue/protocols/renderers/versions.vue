<template>
  <div>
    <div v-if="params.data.urls.show" class="flex items-center gap-2 text-sn-blue">
      <span class="cursor-pointer"
            @click.stop="params.dtComponent.$emit('versions', {}, [params.data])"
            v-if="params.data.nr_of_versions > 0">
        {{ params.data.nr_of_versions }}
      </span>
      <span v-if="params.data.nr_of_versions > 0 && params.data.has_draft">/</span>
      <a v-if="params.data.has_draft" :href="params.data.urls.show_draft" class="hover:no-underline">
        {{ i18n.t("protocols.index.table.draft") }}
      </a>
    </div>
    <div v-else class="flex items-center gap-2 text-sn-grey">
      <span v-if="params.data.nr_of_versions > 0">
        {{ params.data.nr_of_versions }}
      </span>
      <span v-if="params.data.nr_of_versions > 0 && params.data.has_draft">/</span>
      <span v-if="params.data.has_draft" class="hover:no-underline ">
        {{ i18n.t("protocols.index.table.draft") }}
      </span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'VersionsRenderer',
  props: {
    params: {
      required: true
    }
  }
};
</script>
