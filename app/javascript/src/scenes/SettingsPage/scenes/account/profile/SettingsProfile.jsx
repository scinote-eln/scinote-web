import React from "react";

import MyProfile from "./MyProfile";
import MyStatistics from "./MyStatistics";

const SettingsProfile = () =>
  <div>
    <div className="col-xs-12 col-sm-4">
      <MyProfile />
    </div>
    <div className="col-xs-12 col-sm-5">
      <MyStatistics />
    </div>
  </div>;

export default SettingsProfile;
