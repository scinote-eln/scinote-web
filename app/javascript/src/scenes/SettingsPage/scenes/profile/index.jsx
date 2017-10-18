import React from "react";
import DocumentTitle from "react-document-title";
import SettingsAccountWrapper from "../../components/SettingsAccountWrapper";
import MyProfile from "./components/MyProfile";
import MyStatistics from "./components/MyStatistics";

const SettingsProfile = () => (
  <DocumentTitle title="SciNote | Profile">
    <SettingsAccountWrapper>
      <div className="col-xs-12 col-sm-4">
        <MyProfile />
      </div>
      <div className="col-xs-12 col-sm-5">
        <MyStatistics />
      </div>
    </SettingsAccountWrapper>
  </DocumentTitle>
);

export default SettingsProfile;
