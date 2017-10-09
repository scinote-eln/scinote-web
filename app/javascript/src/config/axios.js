// @TODO remove this file ASAP the preferences/profile refactoring is merged
import axios from "axios";
import store from "./store";
import { SIGN_IN_PATH } from "./routes";
import { destroyState } from "../components/actions/UsersActions";

export default axios.create({
  withCredentials: true,
  headers: {
    "X-CSRF-TOKEN": document.querySelector('meta[name="csrf-token"]').content
  },
  validateStatus(status) {
    if (status === 401) {
      store.dispatch(destroyState);
      window.location = SIGN_IN_PATH;
    }
    return status >= 200 && status < 300;
  }
});
