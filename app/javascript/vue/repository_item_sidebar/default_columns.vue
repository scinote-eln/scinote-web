<template>
  <section id="information-section">
    <div ref="information-label" id="information-label"
      class="font-inter text-lg font-semibold leading-7 mb-6 transition-colors duration-300">{{
        i18n.t('repositories.item_card.section.information') }}
    </div>
    <div v-if="row">
      <div class="flex flex-col gap-4">
        <!-- REPOSITORY NAME -->
        <div class="flex flex-col ">
          <span class="inline-block font-semibold pb-[6px]">{{
            i18n.t('repositories.item_card.default_columns.repository_name') }}</span>
          <span v-if="repository?.is_snapshot" class="repository-name text-sn-dark-grey line-clamp-3" :title="repository?.name" data-e2e="e2e-TX-itemCard-inventory">
            {{ repository?.name }}
          </span>
          <a v-else :href="repository?.url" target="_blank" class="repository-name line-clamp-3" :title="repository?.name" data-e2e="e2e-TX-itemCard-inventory">
            {{ repository?.name }}
            <i class="sn-icon sn-icon-open"></i>
          </a>
        </div>

        <div class="sci-divider"></div>

        <!-- CODE -->
        <div class="flex flex-col ">
          <span class="inline-block font-semibold pb-[6px]">{{
            i18n.t('repositories.item_card.default_columns.id')
          }}</span>
          <span class="inline-block text-sn-dark-grey line-clamp-3" :title="row?.code" data-e2e="e2e-TX-itemCard-itemID">
            {{ row?.code }}
          </span>
        </div>

        <div class="sci-divider"></div>

        <!-- ADDED ON -->
        <div class="flex flex-col ">
          <span class="inline-block font-semibold pb-[6px]">{{
            i18n.t('repositories.item_card.default_columns.added_on')
          }}</span>
          <span class="inline-block text-sn-dark-grey" :title="row?.created_at" data-e2e="e2e-TX-itemCard-addedOn">
            {{ row?.created_at }}
          </span>
        </div>

        <div class="sci-divider"></div>

        <!-- ADDED BY -->
        <div class="flex flex-col ">
          <span class="inline-block font-semibold pb-[6px]">{{
            i18n.t('repositories.item_card.default_columns.added_by')
          }}</span>
          <span class="inline-block text-sn-dark-grey line-clamp-3" :title="row?.created_by" data-e2e="e2e-TX-itemCard-addedBy">
            {{ row?.created_by }}
          </span>
        </div>

        <!-- UPDATED ON-->
        <div class="flex flex-col ">
          <span class="inline-block font-semibold pb-[6px]">{{
            i18n.t('repositories.item_card.default_columns.updated_on')
          }}</span>
          <span class="inline-block text-sn-dark-grey line-clamp-3" :title="row?.updated_at" data-e2e="e2e-TX-itemCard-updatedOn">
            {{ row?.updated_at }}
          </span>
        </div>

        <!-- UPDATED BY -->
        <div class="flex flex-col ">
          <span class="inline-block font-semibold pb-[6px]">{{
            i18n.t('repositories.item_card.default_columns.updated_by')
          }}</span>
          <span class="inline-block text-sn-dark-grey line-clamp-3" :title="row?.last_modified_by" data-e2e="e2e-TX-itemCard-updatedBy">
            {{ row?.last_modified_by }}
          </span>
        </div>

        <!-- ARCHIVED ON -->
        <div v-if="row.archived_on" class="flex flex-col ">
          <div class="sci-divider pb-4"></div>
          <span class="inline-block font-semibold pb-[6px]">{{
            i18n.t('repositories.item_card.default_columns.archived_on')
          }}</span>
          <span class="inline-block text-sn-dark-grey" :title="row.archived_on" data-e2e="e2e-TX-itemCard-archivedOn">
            {{ row.archived_on }}
          </span>
        </div>

        <!-- ARCHIVED BY -->
        <div v-if="row.archived_by" class="flex flex-col ">
          <div class="sci-divider pb-4"></div>
          <span class="inline-block font-semibold pb-[6px]">{{
            i18n.t('repositories.item_card.default_columns.archived_by')
          }}</span>
          <span class="inline-block text-sn-dark-grey" :title="row.archived_by" data-e2e="e2e-TX-itemCard-archivedBy">
            {{ row.archived_by }}
          </span>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'RepositoryItemDefaultColumns',
  props: {
    row: { type: Object, default: null },
    repository: { type: Object, default: null }
  }
};
</script>
