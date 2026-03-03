import axios from '../../packs/custom_axios.js';
import {
  user_setting_path,
} from '../../routes.js';

export default {
  methods: {
    setUserState(key, value) {
      axios.put(user_setting_path(key), {user_setting: {value: value}});
    },
    async getUserState(key) {
      const response = await axios.get(user_setting_path(key));
      return response.data.value;
    },
  },
}
