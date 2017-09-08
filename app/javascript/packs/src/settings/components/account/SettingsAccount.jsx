import React, { Component } from "react";
import { Route, Switch } from "react-router-dom";
import styled from "styled-components";

import SettingsLeftTab from "./SettingsLeftTab";
import SettingsProfile from "./profile/SettingsProfile";
import SettingsPreferences from "./preferences/SettingsPreferences";

import { BORDER_LIGHT_COLOR } from "../../../../app/constants/colors";
import {
  SETTINGS_ACCOUNT_PREFERENCES_PATH,
  SETTINGS_ACCOUNT_PROFILE_PATH
} from "../../../../app/routes";

const Wrapper = styled.div`
  background: white;
  box-sizing: border-box;
  border: 1px solid ${BORDER_LIGHT_COLOR};
  border-top: none;
  margin: 0;
  padding: 16px 0 50px 0;
`;

class SettingsAccount extends Component {
  render() {
    return (
      <Wrapper className="row">
        <div className="col-xs-12 col-sm-3">
          <SettingsLeftTab />
        </div>
        <Switch>
          <Route
            path={SETTINGS_ACCOUNT_PROFILE_PATH}
            component={SettingsProfile}
          />
          <Route
            path={SETTINGS_ACCOUNT_PREFERENCES_PATH}
            component={SettingsPreferences}
          />
        </Switch>
      </Wrapper>
    );
  }
}

export default SettingsAccount;
