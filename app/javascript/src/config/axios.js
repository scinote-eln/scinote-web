import axios from "axios";

export default axios.create({
  headers: {
    "X-CSRF-TOKEN": document.querySelector('meta[name="csrf-token"]').content
  }
});
