import axios from "axios";

export const axiosInstance = axios.create({
  withCredentials: true,
  headers: {
    "X-CSRF-TOKEN": document.querySelector('meta[name="csrf-token"]').content
  }
});
