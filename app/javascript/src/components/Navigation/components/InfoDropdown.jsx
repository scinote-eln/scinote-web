//  @flow
import React, { Component } from "react";
import { FormattedMessage } from "react-intl";
import { NavDropdown, MenuItem } from "react-bootstrap";
import {
  CUSTOMER_SUPPORT_LINK,
  TUTORIALS_LINK,
  RELEASE_NOTES_LINK,
  PREMIUM_LINK,
  CONTACT_US_LINK
} from "../../../config/routes";
import { getSciNoteInfo } from "../../../services/api/configurations_api";

import AboutScinoteModal from "./AboutScinoteModal";

type State = {
  scinoteVersion: string,
  addons: Array<string>,
  showModal: boolean
};

class InfoDropdown extends Component<*, State> {
  constructor(props: any) {
    super(props);
    this.state = { showModal: false, scinoteVersion: "", addons: [] };
    (this: any).showAboutSciNoteModal = this.showAboutSciNoteModal.bind(this);
    (this: any).closeModal = this.closeModal.bind(this);
  }

  showAboutSciNoteModal(): void {
    getSciNoteInfo().then(response => {
      const { scinoteVersion, addons } = response;
      (this: any).setState({
        scinoteVersion,
        addons,
        showModal: true
      });
    });
  }

  closeModal(): void {
    (this: any).setState({ showModal: false });
  }

  render() {
    return (
      <NavDropdown
        noCaret
        title={
          <span>
            <span className="fas fa-info-circle" />&nbsp;
            <span className="visible-xs-inline visible-sm-inline">
              <FormattedMessage id="navbar.info_label" />
            </span>
          </span>
        }
        id="nav-info-dropdown"
      >
        <MenuItem href={CUSTOMER_SUPPORT_LINK} target="_blank">
          <FormattedMessage id="info_dropdown.customer_support" />
        </MenuItem>
        <MenuItem href={TUTORIALS_LINK} target="_blank">
          <FormattedMessage id="info_dropdown.tutorials" />
        </MenuItem>
        <MenuItem href={RELEASE_NOTES_LINK} target="_blank">
          <FormattedMessage id="info_dropdown.release_notes" />
        </MenuItem>
        <MenuItem href={PREMIUM_LINK} target="_blank">
          <FormattedMessage id="info_dropdown.premium" />
        </MenuItem>
        <MenuItem href={CONTACT_US_LINK} target="_blank">
          <FormattedMessage id="info_dropdown.contact_us" />
        </MenuItem>
        <MenuItem divider />
        <MenuItem onClick={this.showAboutSciNoteModal}>
          <FormattedMessage id="info_dropdown.about_scinote" />
          <AboutScinoteModal
            showModal={this.state.showModal}
            scinoteVersion={this.state.scinoteVersion}
            addons={this.state.addons}
            onModalClose={this.closeModal}
          />
        </MenuItem>
      </NavDropdown>
    );
  }
}

export default InfoDropdown;
