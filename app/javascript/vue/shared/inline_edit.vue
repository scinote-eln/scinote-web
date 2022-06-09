<template>
  <div class="sci-inline-edit" :class="{ 'editing': editing }">
    <div class="sci-inline-edit__content">
      <textarea
        ref="input"
        rows="1"
        v-if="editing"
        :class="{ 'error': error }"
        :placeholder="placeholder"
        v-model="newValue"
        @input="handleInput"
        @keydown="handleKeypress"
        @paste="handlePaste"
        @blur="handleBlur"
      ></textarea>
      <div v-else @click="enableEdit" class="sci-inline-edit__view" :class="{ 'blank': isBlank }">{{ value || placeholder }}</div>
      <div v-if="editing && error" class="sci-inline-edit__error">
        {{ error }}
      </div>
    </div>
    <template v-if="editing">
      <div class="sci-inline-edit__control btn btn-primary icon-btn" @click="update">
        <i class="fas fa-check"></i>
      </div>
      <div class="sci-inline-edit__control btn btn-light icon-btn" @click="cancelEdit">
        <i class="fas fa-times"></i>
      </div>
    </template>
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
      autofocus: { type: Boolean, default: false },
      multilinePaste: { type: Boolean, default: false }
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
      this.handleAutofocus();
    },
    watch: {
      autofocus() {
        this.handleAutofocus();
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
      handleAutofocus() {
        if (this.autofocus || !this.placeholder && this.isBlank) {
          this.enableEdit();
          setTimeout(this.focus, 50);
        }
      },
      handleBlur() {
        if (!this.isBlank) {
          this.$nextTick(this.update);
        } else {
          this.$emit('delete');
        }
      },
      focus() {
        this.$nextTick(() => {
          if (!this.$refs.input) return;

          this.$refs.input.focus();
          this.resize();
        });
      },
      enableEdit() {
        this.editing = true;
        this.focus();
        this.$emit('editingEnabled');
      },
      cancelEdit() {
        this.editing = false;
        this.newValue = this.value || '';
        this.$emit('editingDisabled');
      },
      handlePaste(e) {
        if (!this.multilinePaste) return;
        e.clipboardData.items[0].getAsString((data) => {
          let lines = data.split(/[\n\r]/);
          if (lines.length > 1) {
            this.newValue = lines[0];
            this.$emit('multilinePaste', lines);
          }
        })
      },
      handleInput() {
        this.newValue = this.newValue.replace(/^[\n\r]+|[\n\r]+$/g, '');
        this.$nextTick(this.resize);
      },
      handleKeypress(e) {
        switch(e.key) {
          case 'Escape':
            this.cancelEdit();
            break;
          case 'Enter':
            this.update();
            break;
        }
      },
      resize() {
        this.$refs.input.style.height = "auto";
        this.$refs.input.style.height = (this.$refs.input.scrollHeight) + "px";
      },
      update() {
        setTimeout(() => {
          if(!this.allowBlank && this.isBlank) return;
          if(!this.editing) return;

          this.newValue = this.newValue.trim();
          this.editing = false;
          this.$emit('editingDisabled');
          this.$emit('update', this.newValue);
        }, 100) // due to clicking 'x' also triggering a blur event
      }
    }
  }
</script>
