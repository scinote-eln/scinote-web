<template>
  <div ref="modal" class="modal fade" id="modal-print-repository-row-label" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
    <div class="modal-dialog" role="document" data-e2e="e2e-MD-printLabel" v-if="fetchedPrintersAndTemplates">
      <div class="modal-content">
        <div v-if="availablePrinters.length > 0" class="printers-available">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
            <div class="modal-title">
              <div v-if="rows.length == 1" class="flex flex-row">
                <div class="font-bold">{{ i18n.t('repository_row.modal_print_label.head_title', {repository_row: rows[0].attributes.name}) }}</div>
                <span class="id-label">
                  {{ i18n.t('repository_row.modal_print_label.id_label', {repository_row_id: rows[0].attributes.code}) }}
                </span>
              </div>
              <div v-else>
                <div class="font-bold">{{ i18n.t('repository_row.modal_print_label.head_title_multiple', {repository_rows: rows.length}) }}</div>
              </div>
            </div>
          </div>
          <div class="modal-body">
            <div class=printers-container>
              <label>
                {{ i18n.t('repository_row.modal_print_label.printer') }}
              </label>
              <SelectDropdown
                :searchable="false"
                :options="availablePrinters"
                @change="selectPrinter"
              />
            </div>

            <div class=labels-container>
              <label>
                {{ i18n.t('repository_row.modal_print_label.label') }}
              </label>

              <SelectDropdown
                ref="labelTemplateDropdown"
                :searchable="false"
                :options="availableTemplates"
                :optionRenderer="templateOption"
                :labelRenderer="templateOption"
                @change="selectTemplate"
              />
              <div v-if="labelTemplateError" class="label-template-warning">
                {{ labelTemplateError }}
              </div>
            </div>
            <p class="sci-input-container">
              <label>
                {{ i18n.t('repository_row.modal_print_label.number_of_copies') }}
              </label>
              <input v-model="copies" type=number class="sci-input-field print-copies-input" min="1">
            </p>
            <div class="label-preview-title">
              {{ i18n.t('repository_row.modal_print_label.label_preview') }}
            </div>
            <div class="label-preview-container">
              <LabelPreview v-if="labelTemplateCode" :zpl='labelTemplateCode' :template="selectedTemplate" :previewUrl="urls.labelPreview" :viewOnly="true"/>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal"> {{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" @click="submitPrint" :disabled="submitting">
              {{ i18n.t(`repository_row.modal_print_label.${labelTemplateError ? 'print_anyway' : 'print_label'}`) }}
            </button>
          </div>
        </div>
        <div v-else class="no-printers-available">
          <div class="modal-body no-printers-container">
            <button type="button" class="close modal-absolute-close-button" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close" data-e2e="e2e-BT-printLabelMD-close"></i></button>
            <img src='/images/printers/no_available_printers.png'>
            <p class="no-printer-title">
              {{ i18n.t('repository_row.modal_print_label.no_printers.title') }}
            </p>
            <p class="no-printer-body">
              {{ i18n.t('repository_row.modal_print_label.no_printers.description') }}
            </p>
          </div>
          <div class="modal-footer">
            <a :href="urls.fluicsInfo" target="blank" class="btn btn-primary" data-e2e="e2e-BT-printLabelMD-visitBlog" >
              {{ i18n.t('repository_row.modal_print_label.no_printers.visit_blog') }}
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global HelperModule */
import SelectDropdown from '../../shared/select_dropdown.vue';
import LabelPreview from '../../label_template/components/label_preview.vue';
import modalMixin from '../../shared/modal_mixin';
import axios from '../../../packs/custom_axios.js';

import {
  print_repositories_path,
  print_zpl_repositories_path,
  label_printers_path,
  list_label_templates_path,
  rows_to_print_repositories_path,
  validate_label_template_columns_repositories_path,
  zpl_preview_label_templates_path
} from '../../../routes.js';

export default {
  name: 'PrintModalContainer',
  props: {
    rowIds: Array,
    repositoryId: Number
  },
  data() {
    return {
      rows: [],
      printers: [],
      templates: [],
      selectedPrinter: null,
      selectedTemplate: null,
      copies: 1,
      zebraPrinters: null,
      labelTemplateError: null,
      labelTemplateCode: null,
      fetchedPrintersAndTemplates: false,
      submitting: false
    };
  },
  components: {
    SelectDropdown,
    LabelPreview
  },
  mixins: [modalMixin],
  mounted() {
    this.initZebraPrinter();
    if (!this.fetchedPrintersAndTemplates) {
      this.validateTemplate();
      axios.get(this.urls.labelTemplates).then((response) => {
        this.templates = response.data.data;
        this.selectDefaultLabelTemplate();
      });

      axios.get(this.urls.printers).then((response) => {
        this.printers = response.data.data;
      });
      this.fetchedPrintersAndTemplates = true;
    }
  },
  computed: {
    urls() {
      return {
        print: print_repositories_path(),
        printValidation: validate_label_template_columns_repositories_path(),
        printers: label_printers_path(),
        labelTemplates: list_label_templates_path(),
        zebraProgress: print_zpl_repositories_path(),
        rows: rows_to_print_repositories_path(),
        labelPreview: zpl_preview_label_templates_path(),
        fluicsInfo: document.getElementById('fluicsInfoUrl').value
      };
    },
    availableTemplates() {
      let { templates } = this;
      if (this.selectedPrinter && this.selectedPrinter.attributes.type_of === 'zebra') {
        templates = templates.filter((i) => i.attributes.type === 'ZebraLabelTemplate');
      }

      return templates.map((i) => ([
        i.id,
        i.attributes.name,
        {
          icon: i.attributes.icon_url,
          description: i.attributes.description || ''
        }
      ])).sort((temp1, temp2) => (temp1.label?.toLowerCase() > temp2.label?.toLowerCase() ? 1 : -1));
    },
    availablePrinters() {
      return this.printers.map((i) => ([
        i.id,
        i.attributes.display_name
      ]));
    }
  },
  watch: {
    rowIds() {
      axios.get(this.urls.rows, { params: { repository_id: this.repositoryId, row_ids: this.rowIds } })
        .then((result) => {
          this.rows = result.data;
        });
    }
  },
  methods: {
    selectDefaultLabelTemplate() {
      if (this.selectedPrinter && this.templates) {
        const template = this.templates.find((i) => i.attributes.default
            && i.type.includes(this.selectedPrinter.attributes.type_of));
      }
    },
    selectPrinter(value) {
      this.selectedPrinter = this.printers.find((i) => i.id === value);
      this.selectDefaultLabelTemplate();
    },
    selectTemplate(value) {
      this.selectedTemplate = this.templates.find((i) => i.id === value);
      this.validateTemplate();
    },
    validateTemplate() {
      if (!this.selectedTemplate || this.rowIds.length == 0) return;

      axios.post(this.urls.printValidation, {
        repository_id: this.repositoryId,
        label_template_id: this.selectedTemplate.id,
        row_ids: this.rowIds
      }).then((response) => {
        this.labelTemplateError = null;
        this.labelTemplateCode = response.data.label_code;
      }).catch((response) => {
        if (response.data) {
          this.labelTemplateError = response.data.error;
          this.labelTemplateCode = response.data.label_code;
        } else {
          this.labelTemplateError = null;
          this.labelTemplateCode = null;
          HelperModule.flashAlertMsg(this.i18n.t('repository_row.modal_print_label.general_error'), 'danger');
        }
      });
    },
    submitPrint() {
      this.submitting = true;

      this.$nextTick(() => {
        if (this.selectedPrinter.attributes.type_of === 'zebra') {
          this.zebraPrinters.print(
            this.urls.zebraProgress,
            '.label-printing-progress-modal',
            '#modal-print-repository-row-label',
            {
              printer_name: this.selectedPrinter.attributes.name,
              number_of_copies: this.copies,
              label_template_id: this.selectedTemplate.id,
              row_ids: this.rowIds,
              repository_id: this.repositoryId
            },
            () => {
              this.submitting = false;
            }
          );
        } else {
          axios.post(this.urls.print, {
            row_ids: this.rowIds,
            repository_id: this.repositoryId,
            label_printer_id: this.selectedPrinter.id,
            label_template_id: this.selectedTemplate.id,
            copies: this.copies
          }).then((response) => {
            $(this.$refs.modal).modal('hide');
            this.$emit('close');
            this.submitting = false;
            PrintProgressModal.init(response.data);
          }).catch(() => {
            this.submitting = false;
            HelperModule.flashAlertMsg(this.i18n.t('repository_row.modal_print_label.general_error'), 'danger');
          });
        }
      });
    },
    initZebraPrinter() {
      this.printers = this.printers.filter((printer) => !printer.id.startsWith('zebra'));
      this.zebraPrinters = zebraPrint.init($('#LabelPrinterSelector'), {
        clearSelectorOnFirstDevice: false,
        appendDevice: (device) => {
          this.printers.push({
            id: `zebra${this.printers.length}`,
            attributes: {
              name: device.name,
              display_name: device.name,
              type_of: 'zebra'
            }
          });
        }
      }, false);
    },
    templateOption(option) {
      return `
          <div class="label-template-option" data-toggle="tooltip" data-placement="right" title="${option[2].description}">
            <img src="${option[2].icon}"></img>
            ${option[1]}
          </div>
        `;
    },
  }
};
</script>
