<template>
  <div class="sci-inline-edit">
    <div class="sci-inline-edit__content">
      <textarea ref="input" v-if="editing" :class="{ 'error': error }" :placeholder="placeholder" v-model="newValue" @input="resize" @blur="update">
      </textarea>
      <span v-else @click="enableEdit" :class="{ 'blank': isBlank }">{{ value || placeholder }}</span>
      <div v-if="editing && error" class="sci-inline-edit__error">
        {{ error }}
      </div>
    </div>
    <div v-if="editing" class="sci-inline-edit__controls">
      <div class="sci-inline-edit__control sci-inline-edit__save">
        <i @click="update" class="fas fa-check"></i>
      </div>
      <div class="sci-inline-edit__control sci-inline-edit__cancel">
        <i @click="cancelEdit" class="fas fa-times"></i>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'InlineEdit',
    props: {
      value: { type: String, default: '' },
      allowBlank: { type: Boolean, default: true },
      attributeName: { type: String, required: true },
      characterLimit: { type: Number },
      placeholder: { type: String },
      autofocus: { type: Boolean, default: false }
    },
    data() {
      return {
        editing: false,
        newValue: ''
      }
    },
    created( ){
      this.newValue = this.value || '';
    },
    mounted() {
      if (this.autofocus) {
        this.editing = true;
        setTimeout(this.focus, 50);
      }
    },
    computed: {
      isBlank() {
        return this.newValue.length === 0
      },
      error() {
        if(!this.allowBlank && this.isBlank) {
          return this.i18n.t('inline_edit.errors.blank', { attribute: this.attributeName })
        }
        if(this.characterLimit && this.newValue.length > this.characterLimit) {
          return(
            this.i18n.t('inline_edit.errors.over_limit',
              { attribute: this.attributeName, limit: this.characterLimit }
            )
          )
        }

        return false
      }
    },
    methods: {
      focus() {
        this.$nextTick(() => {
          this.$refs.input.focus();
          this.resize();
        });
      },
      enableEdit() {
        this.editing = true;
        this.focus();
      },
      cancelEdit() {
        this.editing = false;
        this.newValue = this.value || '';
      },
      resize() {
        this.$refs.input.style.height = "auto";
        this.$refs.input.style.height = (this.$refs.input.scrollHeight * 0.8) + "px";
      },
      update() {
        if(!this.editing) return;

        this.editing = false;
        this.$emit('update', this.newValue);
      }
    }
  }
</script>
