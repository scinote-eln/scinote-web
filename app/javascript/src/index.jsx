import React from "react";
import { BrowserRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { IntlProvider, addLocaleData } from "react-intl";
import enLocaleData from "react-intl/locale-data/en";
import styled from "styled-components";
import { flattenMessages } from "./config/locales/utils";
import messages from "./config/locales/messages";
import store from "./config/store";

import AlertsContainer from "./components/AlertsContainer";
import SettingsPage from "./scenes/SettingsPage";
import Navigation from "./components/Navigation";

addLocaleData([...enLocaleData]);
const locale = "en-US";

const ContentWrapper = styled.div`
  margin-top: 15px;
`;

const ScinoteApp = () =>
  <Provider store={store}>
    <IntlProvider locale={locale}
                  messages={flattenMessages(messages[locale])}>
      <div>
        <BrowserRouter>
          <div>
            <Navigation />
            <AlertsContainer />
            <ContentWrapper>
              <SettingsPage />
            </ContentWrapper>
          </div>
        </BrowserRouter>
      </div>
    </IntlProvider>
  </Provider>;

export default ScinoteApp;
