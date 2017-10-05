import axios from "axios";
// import { dispatch } from "redux";
import store from "../../config/store";
import { SIGN_IN_PATH } from "../../config/routes";
import { destroyState } from "../../components/actions/UsersActions";

export const axiosInstance = axios.create({
  withCredentials: true,
  headers: {
    "X-CSRF-TOKEN": document.querySelector('meta[name="csrf-token"]').content
  },
  validateStatus(status) {
    if (status === 401) {
      setTimeout(() => {
        store.dispatch(destroyState)
        window.location = SIGN_IN_PATH;
      }, 500);
    }
    return status >= 200 && status < 300;
  }
});
