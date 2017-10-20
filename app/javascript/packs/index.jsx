import "babel-polyfill";
import "intl";
import "intl/locale-data/jsonp/en-US.js"
import React from "react";
import ReactDOM from "react-dom";
import App from "../src/";

document.addEventListener("DOMContentLoaded", () => {
  ReactDOM.render(<App />, document.getElementById("root"));
});
