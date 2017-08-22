import React from "react";
import { FormattedMessage } from "react-intl";
import { NavDropdown, MenuItem } from "react-bootstrap";
import {
  CUSTOMER_SUPPORT_LINK,
  TUTORIALS_LINK,
  RELEASE_NOTES_LINK,
  PREMIUM_LINK,
  CONTACT_US_LINK
} from "../../../app/routes";

const InfoDropdown = () =>
  <NavDropdown
    noCaret
    title={
      <span>
        <span className="glyphicon glyphicon-info-sign" />&nbsp;
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
  </NavDropdown>;

export default InfoDropdown;
