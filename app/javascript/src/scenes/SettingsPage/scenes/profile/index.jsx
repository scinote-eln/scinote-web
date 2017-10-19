//  @flow

import React, { Component } from "react";

import PageTitle from "../../../../components/PageTitle";
import SettingsAccountWrapper from "../../components/SettingsAccountWrapper";
import MyProfile from "./components/MyProfile";
import MyStatistics from "./components/MyStatistics";

type Props = {
  tabState: Function
};

class SettingsProfile extends Component<Props> {
  componentDidMount() {
    this.props.tabState("1");
  }

  render() {
    return (
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
  }
}

export default SettingsProfile;
