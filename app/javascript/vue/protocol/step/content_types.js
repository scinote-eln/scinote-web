// One list of the content types a step can hold. It drives both the "Insert content"
// menu and the empty-step tiles, so the two can't drift apart.
//
// Each type: { key, label, icon, emit } for a direct action, or { key, label, icon, submenu }
// for a choice (files, well plate sizes). `disabled` keeps the type visible but inert.
// Actions are MenuDropdown-style emits ('create:text', ...) handled by step.vue#insertContent.
// Expects the host to provide `step`, `urls` and `cantUploadFiles`.

const WELL_PLATE_SIZES = [[32, 48], [16, 24], [8, 12], [6, 8], [4, 6], [3, 4], [2, 3]];

export default {
  computed: {
    wellPlateOptions() {
      const id = this.step.id;
      return [
        {
          text: this.i18n.t('protocols.steps.insert.well_plate_options.custom'),
          emit: 'create:custom_well_plate',
          data_e2e: `e2e-BT-protocol-step${id}-customWellPlate`
        },
        ...WELL_PLATE_SIZES.map(([rows, cols]) => ({
          text: this.i18n.t(`protocols.steps.insert.well_plate_options.${rows}_x_${cols}`),
          emit: 'create:table',
          params: [rows, cols],
          data_e2e: `e2e-BT-protocol-step${id}-insertWellPlate-${rows}`
        }))
      ];
    },
    filesMenu() {
      const id = this.step.id;
      const attrs = this.step.attributes;
      return [
        this.urls.upload_attachment_url && {
          text: this.i18n.t('protocols.steps.insert.add_file'),
          emit: 'create:file',
          data_e2e: `e2e-BT-protocol-step${id}-insertAttachment-file`
        },
        attrs.wopi_enabled && {
          text: this.i18n.t('assets.create_wopi_file.button_text'),
          emit: 'create:wopi_file',
          data_e2e: `e2e-BT-protocol-step${id}-insertAttachment-wopi`
        },
        attrs.open_vector_editor_context?.new_sequence_asset_url && {
          text: this.i18n.t('open_vector_editor.new_sequence_file'),
          emit: 'create:ove_file',
          data_e2e: `e2e-BT-protocol-step${id}-insertAttachment-sequence`
        },
        attrs.marvinjs_enabled && {
          text: this.i18n.t('marvinjs.new_button'),
          emit: 'create:marvinjs_file',
          data_e2e: `e2e-BT-protocol-step${id}-insertAttachment-chemicalDrawing`
        }
      ].filter(Boolean);
    },
    contentTypes() {
      const id = this.step.id;
      const canEdit = !!this.urls.update_url;
      const types = [
        {
          key: 'text',
          available: canEdit,
          label: this.i18n.t('protocols.steps.insert.text'),
          icon: 'sn-icon-result-text',
          emit: 'create:text',
          dataE2e: `e2e-BT-protocol-step${id}-insertText`
        },
        {
          key: 'file',
          available: canEdit && (this.filesMenu.length > 0 || this.cantUploadFiles),
          label: this.i18n.t('protocols.steps.insert.attachment'),
          icon: 'sn-icon-file',
          submenu: this.filesMenu,
          disabled: this.cantUploadFiles,
          dataE2e: `e2e-BT-protocol-step${id}-insertAttachment`
        },
        {
          key: 'form',
          available: !!this.urls.create_form_response_url,
          label: this.i18n.t('protocols.steps.insert.form'),
          icon: 'sn-icon-forms',
          emit: 'create:form',
          dataE2e: `e2e-BT-protocol-step${id}-insertForm`
        },
        {
          key: 'table',
          available: canEdit,
          label: this.i18n.t('protocols.steps.insert.table'),
          icon: 'sn-icon-tables',
          emit: 'create:table',
          dataE2e: `e2e-BT-protocol-step${id}-insertTable`
        },
        {
          key: 'well_plate',
          available: canEdit,
          label: this.i18n.t('protocols.steps.insert.well_plate'),
          icon: 'sn-icon-tables',
          submenu: this.wellPlateOptions,
          dataE2e: `e2e-BT-protocol-step${id}-insertWellplate`
        },
        {
          key: 'checklist',
          available: canEdit,
          label: this.i18n.t('protocols.steps.insert.checklist'),
          icon: 'sn-icon-checkllist',
          emit: 'create:checklist',
          dataE2e: `e2e-BT-protocol-step${id}-insertChecklist`
        }
      ];
      return types.filter((type) => type.available);
    },
    insertMenu() {
      return this.contentTypes.map((type) => ({
        text: type.label,
        icon: `sn-icon ${type.icon}`,
        emit: type.emit,
        submenu: type.submenu,
        position: type.submenu ? 'left' : undefined,
        disabled: type.disabled,
        title: type.disabled ? this.i18n.t('protocols.action_disabled') : '',
        data_e2e: type.dataE2e
      }));
    }
  }
};
