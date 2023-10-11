import axios from "axios";

const instance = axios.create({
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
});

instance.interceptors.request.use(
  function (config) {
    const csrfToken = document.querySelector('[name=csrf-token]').content;
    config.headers["X-CSRF-Token"] = csrfToken;

    return config;
  },
  function (error) {
    return Promise.reject(error);
  }
);

export default instance;
