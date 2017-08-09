import React from "react";

export default ({ className, children }) =>
  <li className={className} role="presentation">
    {children}
  </li>;
