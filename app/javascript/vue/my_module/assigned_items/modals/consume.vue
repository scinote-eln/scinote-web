<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content" v-if="consumeData">
        <div class="modal-header">
            <button type="button" class="close self-start" data-dismiss="modal" aria-label="<%= t('general.close') %>">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title">
              <span v-if="consumeData.consumed_stock">{{ i18n.t('my_modules.repository.stock_modal.title_edit', { name: consumeData.name  }) }}</span>
              <span v-else>{{ i18n.t('my_modules.repository.stock_modal.title', { name: consumeData.name }) }}</span>
            </h4>
          </div>
          <div class="modal-body">
            <p class="mb-6">{{ i18n.t('my_modules.repository.stock_modal.description') }}</p>
            <div class="mb-6">
              <label>{{ i18n.t('my_modules.repository.stock_modal.amount') }}</label>
              <div class="sci-input-container-v2 flex"
                   :class="{'error': newConsume.consume < 0}"
                   :data-error-text="i18n.t('repository_stock_values.manage_modal.amount_error')">
                <input type="text"
                       class="sci-input-field !w-32"
                       :value="newConsume.consume"
                       @input="changeConsume"
                       :placeholder="i18n.t('my_modules.repository.stock_modal.consumed')"
                       tabindex="1" />
                <span class="units relative left-32 ml-1">{{ consumeData.unit }}</span>
              </div>
            </div>
            <div class="items-center grid grid-cols-[1fr,auto,1fr] gap-2 mb-6">
              <div class="py-2 bg-sn-super-light-grey flex rounder items-center flex-col gap-2" :class="{'text-sn-alert-passion': consumeData.initial_stock < 0}">
                <span class="text-xs text-sn-grey-500">{{ i18n.t('repository_stock_values.manage_modal.current_stock') }}</span>
                <h1 class="my-0">{{ consumeData.formatted_stock }}</h1>
                <span class="text-xs">{{ consumeData.unit }}</span>
              </div>
              <div class="p-4">
                <i class="sn-icon sn-icon-arrow-right"></i>
              </div>
              <div class="py-2 bg-sn-super-light-grey px-2 bg-sn-super-light-grey flex rounder items-center flex-col gap-2"
                   :class="{'text-sn-alert-passion': finalStock < 0}"
              >
                <span class="text-sm text-sn-grey-500">{{ i18n.t('repository_stock_values.manage_modal.new_stock') }}</span>
                <h1 class="my-0">{{ finalStock || '-' }}</h1>
                <span class="text-xs">{{ consumeData.unit }}</span>
              </div>
            </div>
            <label>{{ i18n.t('my_modules.repository.stock_modal.comment') }}</label>
            <div class="sci-input-container-v2 comments-container"  data-error-text="<%= t('repository_stock_values.manage_modal.comment_limit') %>">
              <input type="text" class="sci-input-field"
                     v-model="newConsume.comment" :placeholder="i18n.t('my_modules.repository.stock_modal.enter_comment')" tabindex="1" />
            </div>
          </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button type="button" class="btn btn-primary"
                  @click="$emit('updateConsume', {newConsume: newConsume, finalStock: finalStock})"
                  :disabled="!validConsume">{{ i18n.t('general.save') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global Decimal formatDecimalValue */

import axios from '../../../../packs/custom_axios.js';
import modalMixin from '../../../shared/modal_mixin';

export default {
  name: 'EditModal',
  props: {
    row: Object
  },
  data() {
    return {
      consumeData: null,
      initialValue: null,
      initialStock: null,
      finalStock: null,
      newConsume: {
        consume: null,
        comment: null,
        unit: null,
        url: null
      }
    };
  },
  created() {
    this.getConsumeData();
  },
  mixins: [modalMixin],
  computed: {
    validConsume() {
      return this.newConsume.consume >= 0;
    }
  },
  methods: {
    getConsumeData() {
      axios.get(this.row.consumed_stock.update_stock_consumption_url)
        .then((response) => {
          this.consumeData = response.data;
          if (this.consumeData.formatted_stock_consumption) {
            this.newConsume.consume = new Decimal(this.consumeData.formatted_stock_consumption);
          }
          this.newConsume.unit = this.consumeData.unit;
          this.newConsume.url = this.consumeData.update_url;
          this.initialStock = new Decimal(this.consumeData.initial_stock);
          this.initialValue = this.newConsume.consume || new Decimal(0);
        });
    },
    changeConsume(e) {
      const { value } = e.target;
      this.newConsume.consume = formatDecimalValue(String(value), this.consumeData.decimals);
      this.finalStock = this.initialValue.minus(new Decimal(this.newConsume.consume || 0)).plus(this.initialStock);
      if (e.target.value.length === 0) {
        e.target.parentNode.dataset.errorText = this.i18n.t('repository_stock_values.manage_modal.amount_error');
      } else if (e.target.value <= 0) {
        e.target.parentNode.dataset.errorText = this.i18n.t('repository_stock_values.manage_modal.negative_error');
      }
    }
  }
};
</script>
