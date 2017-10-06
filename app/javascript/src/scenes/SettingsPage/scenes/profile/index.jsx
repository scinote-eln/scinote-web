import React from "react";
import SettingsAccountWrapper from "../../components/SettingsAccountWrapper";
import MyProfile from "./components/MyProfile";
import MyStatistics from "./components/MyStatistics";

const SettingsProfile = () =>
  <SettingsAccountWrapper>
    <div className="col-xs-12 col-sm-4">
      <MyProfile />
    </div>
    <div className="col-xs-12 col-sm-5">
      <MyStatistics />
    </div>
  </SettingsAccountWrapper>;

export default SettingsProfile;
