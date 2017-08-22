import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter, Route, Switch, Redirect } from "react-router-dom";
import { Provider } from "react-redux";
import { IntlProvider, addLocaleData } from "react-intl";
import enLocaleData from "react-intl/locale-data/en";

import { flattenMessages } from "../../locales/utils";
import store from "../../app/store";
import messages from "../../locales/messages";

import Navigation from "../../shared/navigation";
import NotFound from "../../shared/404/NotFound";
import MainNav from "./components/MainNav";
import SettingsAccount from "./components/account/SettingsAccount";
import SettingsTeams from "./components/team/SettingsTeams";

addLocaleData([...enLocaleData]);
const locale = "en-US";

const SettingsPage = () =>
  <div>
    <Navigation page="Settings" />
    <div className="container">
      <MainNav />
      <Switch>
        <Route exact path="/" component={SettingsAccount} />
        <Route
          exact
          path="/settings"
          render={() => <Redirect to="/settings/account/profile" />}
        />
        <Route path="/settings/account" component={SettingsAccount} />
        <Route path="/settings/teams" component={SettingsTeams} />
        <Route component={NotFound} />
      </Switch>
    </div>
  </div>;

document.addEventListener("DOMContentLoaded", () => {
  ReactDOM.render(
    <Provider store={store}>
      <IntlProvider
        locale={locale}
        messages={flattenMessages(messages[locale])}
      >
        <div>
          <BrowserRouter>
            <SettingsPage />
          </BrowserRouter>
        </div>
      </IntlProvider>
    </Provider>,
    document.getElementById("root")
  );
});
