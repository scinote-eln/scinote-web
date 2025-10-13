<template>
  <div class="bg-white px-4 my-4 task-section">
    <div class="py-4 flex items-center gap-4">
      <i ref="openHandler"
        @click="toggleContainer"
        class="sn-icon sn-icon-right cursor-pointer">
      </i>
      <div class="flex items-center gap-2">
        <h2 class="my-0 flex items-center gap-1">
          {{ i18n.t('my_modules.details.title') }}
        </h2>
        <GeneralDropdown ref="myModuleDetailsDropdown">
          <template v-slot:field>
            <button class="btn btn-light btn-black icon-btn">
              <i class="sn-icon sn-icon-info"></i>
            </button>
          </template>
          <template v-slot:flyout>
            <div class="grid grid-cols-[auto_1fr] gap-y-2 gap-x-4 py-2.5 max-h-[inherit] w-[400px] p-4">
              <div class="font-bold text-sm">
                {{ i18n.t('my_modules.details.info_popover.project_label') }}
              </div>
              <div class="text-sm truncate" :title="myModule.attributes.project_name">
                {{  myModule.attributes.project_name }}
              </div>
              <div class="font-bold text-sm">
                {{ i18n.t('my_modules.details.info_popover.experiment_label') }}
              </div>
              <div class="text-sm truncate" :title="myModule.attributes.experiment_name">
                {{ myModule.attributes.experiment_name }}
              </div>
              <div class="font-bold text-sm">
                {{ i18n.t('my_modules.details.info_popover.creator_label') }}
              </div>
              <div class="text-sm truncate" :title="myModule.attributes.created_by_name">
                {{ myModule.attributes.created_by_name }}
                <span v-if="myModule.attributes.is_creator_current_user">
                  ({{ i18n.t('my_modules.details.info_popover.creator_same_user_label') }})
                </span>
              </div>
              <div class="font-bold text-sm">
                {{ i18n.t('my_modules.details.info_popover.created_label') }}
              </div>
              <div class="text-sm truncate">
                {{ myModule.attributes.created_at }}
              </div>
              <div class="font-bold text-sm">
                {{ i18n.t('my_modules.details.info_popover.modified_label') }}
              </div>
              <div class="text-sm truncate" :title="myModule.attributes.last_modified_by_name">
                <span v-if="myModule.attributes.last_modified_by_name">
                  {{ i18n.t('my_modules.details.info_popover.modified_value',
                    {
                      date: myModule.attributes.updated_at,
                      full_name: myModule.attributes.last_modified_by_name
                    }) }}
                </span>
                <span v-else class="truncate">
                  {{ i18n.t('my_modules.details.info_popover.modified_value_without_user',
                    {
                      date: myModule.attributes.updated_at
                    }) }}
                </span>
              </div>
              <div class="col-span-2 text-sm">
                <a href="#" @click.prevent="openAccessModal">
                  {{ i18n.t('my_modules.details.info_popover.view_task_access') }}
                </a>
              </div>
            </div>
          </template>
        </GeneralDropdown>
        <span>
          {{ myModule.attributes.code }}
        </span>
      </div>
    </div>
    <div ref="detailsContainer" class="overflow-hidden flex flex-col gap-1 transition-all pr-4 pl-9" style="max-height: 0px;">
      <div class="flex items-center">
        <span class="sn-icon sn-icon-calendar"></span>
        <span class="tw-hidden lg:block ml-2">
          {{ i18n.t('my_modules.details.start_date') }}
        </span>
        <div class="w-48">
          <DateTimePicker
            v-if="myModule.attributes.permissions.manage_due_date"
            @change="setStartDate"
            :defaultValue="startDate"
            mode="datetime"
            :class="{'font-bold': myModule.attributes.start_date_cell.value_formatted}"
            size="mb"
            :noBorder="true"
            :noIcons="true"
            valueType="stringWithoutTimezone"
            :placeholder="i18n.t('my_modules.details.no_start_date_placeholder')"
            :clearable="true"
          />
          <div v-else class="ml-2 py-2">
            <span v-if="myModule.attributes.start_date_cell.value_formatted" class="font-bold">{{ myModule.attributes.start_date_cell.value_formatted }}</span>
            <span v-else class="text-sn-grey">{{ i18n.t('my_modules.details.no_due_date') }}</span>
          </div>
        </div>
      </div>
      <div class="flex items-center">
        <span class="sn-icon sn-icon-calendar"></span>
        <span class="tw-hidden lg:block ml-2">
          {{ i18n.t('my_modules.details.due_date') }}
        </span>
        <div class="w-48">
          <DateTimePicker
            v-if="myModule.attributes.permissions.manage_due_date"
            @change="setDueDate"
            mode="datetime"
            :defaultValue="dueDate"
            :class="{'font-bold': myModule.attributes.due_date_cell.value_formatted}"
            size="mb"
            :noBorder="true"
            :noIcons="true"
            valueType="stringWithoutTimezone"
            :placeholder="i18n.t('my_modules.details.no_due_date_placeholder')"
            :clearable="true"
          />
          <div v-else class="ml-2 py-2">
            <span v-if="myModule.attributes.due_date_cell.value_formatted" class="font-bold">{{ myModule.attributes.due_date_cell.value_formatted }}</span>
            <span v-else class="text-sn-grey">{{ i18n.t('my_modules.details.no_due_date') }}</span>
          </div>
        </div>
      </div>
      <div v-if="myModule.attributes.completed_on" class="flex items-center gap-2 h-10">
        <span class="sn-icon sn-icon-calendar"></span>
        <span class="tw-hidden lg:block">
          {{ i18n.t('my_modules.details.completed_date') }}
        </span>
      </div>
      <div class="flex gap-2 mt-2.5">
        <span class="sn-icon sn-icon-users"></span>
        <span class="tw-hidden lg:block shrink-0">
          {{ i18n.t('my_modules.details.assigned_users') }}
        </span>
        <div class="grow -mt-2.5">
          <SelectDropdown
            v-if="myModule.attributes.permissions.manage_designated_users"
            @change="setUsers"
            :options="formattedUsers"
            :option-renderer="usersRenderer"
            :label-renderer="usersRenderer"
            :multiple="true"
            class="grow"
            :value="users"
            :searchable="true"
            :placeholder="i18n.t('experiments.canvas.new_my_module_modal.assigned_users_placeholder')"
            :tagsView="true">
          </SelectDropdown>
          <div v-else class="flex items-center flex-wrap gap-2 mt-2.5">
            <div class="sci-tag bg-sn-super-light-grey" v-for="user in selectedUsers" :key="user.id">
              <img :src="user.attributes.avatar_url" class="rounded-full w-5 h-5" />
              <span :title="user.attributes.name" class="truncate">{{ user.attributes.name }}</span>
            </div>
          </div>
        </div>
      </div>
      <div class="flex gap-2 mb-6 mt-2.5">
        <span class="sn-icon sn-icon-tag"></span>
        <span class="tw-hidden lg:block shrink-0">
          {{ i18n.t('my_modules.details.tags') }}
        </span>
        <div class="grow -mt-1.5">
          <TagsInput :subject="myModule" :key="detailsKey" v-if="myModule" @reloadSubject="$emit('reloadMyModule')" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import GeneralDropdown from '../shared/general_dropdown.vue';
import DateTimePicker from '../shared/date_time_picker.vue';
import SelectDropdown from '../shared/select_dropdown.vue';
import TagsInput from '../shared/tags_input.vue';
import axios from '../../packs/custom_axios.js';
import escapeHtml from '../shared/escape_html.js';
import usersRenderer from '../shared/select_dropdown_renderers/user.vue';
import {
  my_module_path,
  assigned_users_my_module_path,
  designate_users_my_module_user_my_modules_path
} from '../../routes.js';

export default {
  name: 'MyModuleDetails',
  props: {
    myModule: {
      type: Object,
      required: true
    },
    detailsKey: {
      type: Number,
      required: true
    }
  },
  components: {
    GeneralDropdown,
    DateTimePicker,
    SelectDropdown,
    TagsInput,
    usersRenderer,
  },
  data() {
    return {
      sectionOpened: false,
      allUsers: [],
      users: [],
      startDate: null,
      dueDate: null,
      usersRenderer: usersRenderer,
    };
  },
  mixins: [escapeHtml],
  computed: {
    formattedUsers() {
      return this.allUsers.map((user) => (
        [
          parseInt(user.id, 10),
          user.attributes.name,
          { avatar_url: user.attributes.avatar_url }
        ]
      ));
    },
    selectedUsers() {
      return this.allUsers.filter(user => this.users.includes(parseInt(user.id, 10)));
    }
  },
  created() {
    if (this.myModule.attributes.start_date_cell.value) {
      this.startDate = new Date(this.myModule.attributes.start_date_cell.value);
    }
    if (this.myModule.attributes.due_date_cell.value) {
      this.dueDate = new Date(this.myModule.attributes.due_date_cell.value);
    }
  },
  mounted() {
    this.loadUsers();
  },
  methods: {
    updateUrl() {
      return my_module_path(this.myModule.id);
    },
    recalculateContainerSize(offset = 0) {
      const container = this.$refs.detailsContainer;
      const handler = this.$refs.openHandler;

      if (this.sectionOpened) {
        container.style.maxHeight = `${container.scrollHeight + offset}px`;
        handler.classList.remove('sn-icon-right');
        handler.classList.add('sn-icon-down');
      } else {
        container.style.maxHeight = '0px';
        handler.classList.remove('sn-icon-down');
        handler.classList.add('sn-icon-right');
      }
    },
    toggleContainer() {
      this.sectionOpened = !this.sectionOpened;
      this.recalculateContainerSize(60);
    },
    reloadMyModule() {
      this.$emit('reloadMyModule');
    },
    openAccessModal() {
      // Legacy part - to be updated
      const container = document.getElementById('accessModalContainer');
      this.$refs.myModuleDetailsDropdown.isOpen = false;
      $.get(container.dataset.url, (data) => {
        const object = {
          ...data.data.attributes,
          id: data.data.id,
          type: data.data.type
        };
        const { rolesUrl } = container.dataset;
        const params = {
          object: object,
          roles_path: rolesUrl
        };
        const modal = $('#accessModalComponent').data('accessModal');
        modal.params = params;
        modal.open();
      });
    },
    loadUsers() {
      const usersUrl = assigned_users_my_module_path(this.myModule.id);
      axios.get(usersUrl).then((response) => {
        this.allUsers = response.data.data;
        this.users = this.myModule.attributes.designated_user_ids || [];
      });
    },
    setDueDate(value) {
      const updateUrl = my_module_path(this.myModule.id);
      axios.put(updateUrl, {
        my_module: {
          due_date: value,
        }
      }).then(() => {
        this.reloadMyModule();
      });
    },
    setStartDate(value) {
      const updateUrl = my_module_path(this.myModule.id);
      axios.put(updateUrl, {
        my_module: {
          started_on: value,
        }
      }).then(() => {
        this.reloadMyModule();
      });
    },
    setUsers(value) {
      axios.post(designate_users_my_module_user_my_modules_path({ my_module_id: this.myModule.id }), {
        user_ids: value
      }).then(() => {
        this.reloadMyModule();
      })
    }
  }
};
</script>
