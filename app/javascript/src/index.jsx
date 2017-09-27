import React, { Component } from "react";
import { BrowserRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { IntlProvider, addLocaleData } from "react-intl";
import enLocaleData from "react-intl/locale-data/en";
import { flattenMessages } from "./config/locales/utils";
import messages from "./config/locales/messages";
import store from "./config/store";

import Spinner from "./components/Spinner";
import Alert from "./components/Alert";
import ModalsContainer from "./components/ModalsContainer";
import SettingsPage from "./scenes/SettingsPage";
import Navigation from "./components/Navigation";

addLocaleData([...enLocaleData]);
const locale = "en-US";

class ScinoteApp extends Component {
  constructor(props) {
    super(props);
    const a = 5;
  }

  render() {
    return (
      <Provider store={store}>
        <IntlProvider locale={locale}
                      messages={flattenMessages(messages[locale])}
        >
          <div>
            <BrowserRouter>
              <div>
                <Navigation />
                <div>
                  <Alert message={{type: "alert", text: "Yadayadayada!!!"}} />
                </div>
                <SettingsPage />
              </div>
            </BrowserRouter>

            <ModalsContainer />
            <Spinner />
          </div>
        </IntlProvider>
      </Provider>
    );
  }
}

export default ScinoteApp;
