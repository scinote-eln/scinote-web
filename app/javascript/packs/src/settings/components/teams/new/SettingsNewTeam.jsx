import React, { Component } from "react";
import update from "immutability-helper";
import styled from "styled-components";
import axios from "../../../../../app/axios";
import { Breadcrumb, FormGroup, FormControl, ControlLabel, HelpBlock, Button } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";
import { FormattedMessage } from "react-intl";

import { SETTINGS_TEAMS_ROUTE } from "../../../../../app/dom_routes";
import { TEAMS_NEW_PATH } from "../../../../../app/routes";
import {
  NAME_MIN_LENGTH,
  NAME_MAX_LENGTH,
  TEXT_MAX_LENGTH
} from "../../../../../app/constants/numeric";
import { BORDER_LIGHT_COLOR } from "../../../../../app/constants/colors";

import NameFormControl from "./components/NameFormControl";

const Wrapper = styled.div`
  background: white;
  box-sizing: border-box;
  border: 1px solid ${BORDER_LIGHT_COLOR};
  border-top: none;
  margin: 0;
  padding: 16px 15px 50px 15px;
`;

class SettingsNewTeam extends Component {
  constructor(props) {
    super(props);
    this.state = {
      team: {
        name: {
          value: "",
          errorMessage: "",
        },
        description: {
          value: "",
          errorMessage: "",
        }
      }
    };

    this.getValidationState = this.getValidationState.bind(this);
    this.validateField = this.validateField.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);
  }

  getValidationState(attr) {
    if (this.state.team[attr].errorMessage.length > 0) {
      return "error";
    }
    return null;
  }

  validateField(key, value) {
    let errorMessage;
    if (key === "name") {
      errorMessage = "";

      if (value.length < NAME_MIN_LENGTH) {
        errorMessage = <FormattedMessage id="error_messages.text_too_short" values={{ min_length: NAME_MIN_LENGTH }} />;
      } else if (value.length > NAME_MAX_LENGTH) {
        errorMessage = <FormattedMessage id="error_messages.text_too_long" values={{ max_length: NAME_MAX_LENGTH }} />;
      }

      this.newState = update(
        this.newState,
        { team: { name: { errorMessage: { $set: errorMessage } } } }
      );
    } else if (key === "description") {
      errorMessage = "";

      if (value.length > TEXT_MAX_LENGTH) {
        errorMessage = <FormattedMessage id="error_messages.text_too_long" values={{ max_length: TEXT_MAX_LENGTH }} />;
      }

      this.newState = update(
        this.newState,
        { team: { description: { errorMessage: { $set: errorMessage } } } }
      );
    }
  }

  handleChange(e) {
    const key = e.target.name;
    const value = e.target.value;

    this.newState = { ...this.state };

    // Update value in the state
    this.newState = update(
      this.newState,
      { team: { [key]: { value: { $set: value } } } }
    );

    // Validate the input
    this.validateField(key, value);

    // Refresh state
    this.setState(this.newState);
  }

  onSubmit() {
    axios({
      method: "post",
      url: TEAMS_NEW_PATH,
      withCredentials: true,
      data: { team: this.state.team }
    })
      .then(response => {
        // TODO: Redirect to team page
      })
      .catch(error => this.setState({ errorMessage: error.message }));
  }

  render() {
    return (
      <Wrapper>
        <Breadcrumb>
          <LinkContainer to={SETTINGS_TEAMS_ROUTE}>
            <Breadcrumb.Item>
              <FormattedMessage id="settings_page.all_teams" />
            </Breadcrumb.Item>
          </LinkContainer>
          <Breadcrumb.Item active={true}>
            <FormattedMessage id="settings_page.new_team.title" />
          </Breadcrumb.Item>
        </Breadcrumb>

        <form onSubmit={this.onSubmit} style={{ maxWidth: "500px" }}>

          <FormGroup
            controlId="formTeamName"
            validationState={this.getValidationState("name")}
          >
            <ControlLabel>
              <FormattedMessage id="settings_page.new_team.name_label" />
            </ControlLabel>
            <NameFormControl
              value={this.state.team.name.value}
              onChange={this.handleChange}
              name="name"
            />
            <FormControl.Feedback />
            <HelpBlock>{this.state.team.name.errorMessage}</HelpBlock>
          </FormGroup>
          <small>
            <FormattedMessage id="settings_page.new_team.name_sublabel" />
          </small>
          <br />
          <br />

          <FormGroup
            controlId="formTeamDescription"
            validationState={this.getValidationState("description")}
          >
            <ControlLabel>
              <FormattedMessage id="settings_page.new_team.description_label" />
            </ControlLabel>
            <FormControl
              componentClass="textarea"
              value={this.state.team.description.value}
              onChange={this.handleChange}
              name="description"
            />
            <FormControl.Feedback />
            <HelpBlock>{this.state.team.description.errorMessage}</HelpBlock>
          </FormGroup>
          <small>
            <FormattedMessage id="settings_page.new_team.description_sublabel" />
          </small>
          <br />
          <br />

          <LinkContainer to={SETTINGS_TEAMS_ROUTE}>
            <Button>
              <FormattedMessage id="general.cancel" />
            </Button>
          </LinkContainer>
          <Button type="submit" className="btn-primary">
            <FormattedMessage id="settings_page.new_team.create" />
          </Button>
        </form>
      </Wrapper>
    );
  }
}

export default SettingsNewTeam;