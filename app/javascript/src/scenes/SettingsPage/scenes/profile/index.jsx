import React from "react";
import DocumentTitle from "react-document-title";

import PageTitle from "../../../../components/PageTitle";
import SettingsAccountWrapper from "../../components/SettingsAccountWrapper";
import MyProfile from "./components/MyProfile";
import MyStatistics from "./components/MyStatistics";

const SettingsProfile = () => (
  <PageTitle localeID="page_title.settings_profile_page">
    <SettingsAccountWrapper>
      <div className="col-xs-12 col-sm-4">
        <MyProfile />
      </div>
      <div className="col-xs-12 col-sm-5">
        <MyStatistics />
      </div>
    </SettingsAccountWrapper>
  </PageTitle>
);

export default SettingsProfile;
