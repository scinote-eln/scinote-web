import React from "react";
import ReactDOM from "react-dom";
import { Provider } from "react-redux";
import { IntlProvider } from "react-intl";
import { addLocaleData } from "react-intl";
import enLocaleData from "react-intl/locale-data/en";
import { flattenMessages } from "../../locales/utils";
import store from "../../app/store";
import messages from "../../locales/messages";

import Navigation from "../../shared/navigation";

addLocaleData([...enLocaleData]);
let locale = "en-US";

const SettingsPage = () =>
  <div>
    <Navigation page="Settings" />
    ....
  </div>;

document.addEventListener("DOMContentLoaded", () => {
  ReactDOM.render(
    <Provider store={store}>
      <IntlProvider
        locale={locale}
        messages={flattenMessages(messages[locale])}
      >
        <SettingsPage />
      </IntlProvider>
    </Provider>,
    document.getElementById("root")
  );
});
