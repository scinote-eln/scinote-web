import axios from "axios";

export const axiosInstance = axios.create({
  withCredentials: true,
  headers: {
    "X-CSRF-TOKEN": document.querySelector('meta[name="csrf-token"]').content
  }
});

// handles unsuccessful responses
export class ResponseError extends Error {
  constructor(response = "", ...args) {
    super(...args);

    this.response = response;
  }
}
