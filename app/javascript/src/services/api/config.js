import axios from "axios";
import store from "../../config/store";
import { SIGN_IN_PATH } from "../../config/routes";
import { destroyState } from "../../components/actions/UsersActions";

// estimate time react component needs to rerender after state refresh
const TimeDelay = 500;

const axiosInstance = axios.create({
  withCredentials: true,
  headers: {
    "X-CSRF-TOKEN": document.querySelector('meta[name="csrf-token"]').content
  },
  validateStatus(status) {
    if (status === 401) {
      setTimeout(() => {
        store.dispatch(destroyState)
        window.location = SIGN_IN_PATH;
      }, TimeDelay);
    }
    return status >= 200 && status < 300;
  }
});

// Set global IN_REQUEST variable needed for wait_for_ajax function in cucumber tests
axiosInstance.interceptors.request.use((config) => {
  window.IN_REQUEST = true;
  return config;
}, (error) => {
  setTimeout(() => {
    window.IN_REQUEST = false;
  }, TimeDelay)
  return Promise.reject(error);
});

axiosInstance.interceptors.response.use((response) => {
  setTimeout(() => {
    window.IN_REQUEST = false;
  }, TimeDelay)
  return response;
}, (error) => {
  setTimeout(() => {
    window.IN_REQUEST = false;
  }, TimeDelay)
  return Promise.reject(error);
});

export default axiosInstance;
