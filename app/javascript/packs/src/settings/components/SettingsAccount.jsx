import React, { Component } from "react";
import { Route, Switch } from "react-router-dom";

import SettingsLeftTab from "./SettingsLeftTab";
import SettingsProfile from "./SettingsProfile";
import SettingsPreferences from "./SettingsPreferences";

class SettingsAccount extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <div className="row">
        <div className="col-xs-12 col-sm-3">
          <SettingsLeftTab />
        </div>
        <Switch>
          <Route path="/settings/account/profile" component={SettingsProfile} />
          <Route
            path="/settings/account/preferences"
            component={SettingsPreferences}
          />
        </Switch>
      </div>
    );
  }
}

export default SettingsAccount;
