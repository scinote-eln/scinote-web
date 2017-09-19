import React, { Component } from "react";
import { Breadcrumb, FormGroup, FormControl, ControlLabel, HelpBlock, Button } from "react-bootstrap";
import { Redirect } from "react-router";
import { LinkContainer } from "react-router-bootstrap";
import { FormattedMessage } from "react-intl";
import update from "immutability-helper";
import styled from "styled-components";
import axios from "../../../../../config/axios";
import _ from "lodash";
import {
  SETTINGS_TEAMS_ROUTE,
  SETTINGS_TEAM_ROUTE
} from "../../../../../config/routes";
import { TEAMS_NEW_PATH } from "../../../../../config/api_endpoints";
import {
  NAME_MIN_LENGTH,
  NAME_MAX_LENGTH,
  TEXT_MAX_LENGTH
} from "../../../../../config/constants/numeric";

import { BORDER_LIGHT_COLOR } from "../../../../../config/constants/colors";

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
        name: "",
        description: "",
      },
      formErrors: {
        name: "",
        description: ""
      },
      redirectTo: ""
    };

    this.onSubmit = this.onSubmit.bind(this);
    this.validateField = this.validateField.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.renderTeamNameFormGroup = this.renderTeamNameFormGroup.bind(this);
    this.renderTeamDescriptionFormGroup = this.renderTeamDescriptionFormGroup.bind(this);
  }

  onSubmit(e) {
    e.preventDefault();

    axios({
      method: "post",
      url: TEAMS_NEW_PATH,
      withCredentials: true,
      data: { team: this.state.team }
    })
      .then(sr => {
        // Redirect to the new team page
        this.newState = { ...this.state };
        this.newState = update(
          this.newState,
          { redirectTo: {
              $set: SETTINGS_TEAM_ROUTE.replace(':id', sr.data.details.id)
            }
          }
        );
        this.setState(this.newState);
      })
      .catch(er => {
        // Display errors
        this.newState = { ...this.state };
        ['name', 'description'].forEach((el) => {
          if (er.response.data.details[el]) {
            this.newState = update(
              this.newState,
              { formErrors: { name: { $set: <span>{er.response.data.details[el]}</span> } } }
            );
          }
        });
        this.setState(this.newState);
      });
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
        { formErrors: { name: { $set: errorMessage } } }
      );
    } else if (key === "description") {
      errorMessage = "";

      if (value.length > TEXT_MAX_LENGTH) {
        errorMessage = <FormattedMessage id="error_messages.text_too_long" values={{ max_length: TEXT_MAX_LENGTH }} />;
      }

      this.newState = update(
        this.newState,
        { formErrors: { description: { $set: errorMessage } } }
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
      { team: { [key]: { $set: value } } }
    );

    // Validate the input
    this.validateField(key, value);

    // Refresh state
    this.setState(this.newState);
  }

  renderTeamNameFormGroup() {
    const formGroupClass = this.state.formErrors.name ? "form-group has-error" : "form-group";
    const validationState = this.state.formErrors.name ? "error" : null;
    return (
      <FormGroup
        controlId="formTeamName"
        className={formGroupClass}
        validationState={validationState}
      >
        <ControlLabel>
          <FormattedMessage id="settings_page.new_team.name_label" />
        </ControlLabel>
        <NameFormControl
          value={this.state.team.name}
          onChange={this.handleChange}
          name="name"
        />
        <FormControl.Feedback />
        <HelpBlock>{this.state.formErrors.name}</HelpBlock>
      </FormGroup>
    );
  }

  renderTeamDescriptionFormGroup() {
    const formGroupClass = this.state.formErrors.description ? "form-group has-error" : "form-group";
    const validationState = this.state.formErrors.description ? "error" : null;
    return (
      <FormGroup
        controlId="formTeamDescription"
        className={formGroupClass}
        validationState={validationState}
      >
        <ControlLabel>
          <FormattedMessage id="settings_page.new_team.description_label" />
        </ControlLabel>
        <FormControl
          componentClass="textarea"
          value={this.state.team.description}
          onChange={this.handleChange}
          name="description"
        />
        <FormControl.Feedback />
        <HelpBlock>{this.state.formErrors.description}</HelpBlock>
      </FormGroup>
    );
  }

  render() {
    // Redirect if form successful
    if (!_.isEmpty(this.state.redirectTo)) {
      return <Redirect to={this.state.redirectTo} />;
    }

    const btnDisabled = !_.isEmpty(this.state.formErrors.name) ||
                        !_.isEmpty(this.state.formErrors.description);

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

          {this.renderTeamNameFormGroup()}
          <small>
            <FormattedMessage id="settings_page.new_team.name_sublabel" />
          </small>
          <br />
          <br />

          {this.renderTeamDescriptionFormGroup()}
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
          <Button type="submit" className="btn-primary" disabled={btnDisabled}>
            <FormattedMessage id="settings_page.new_team.create" />
          </Button>

        </form>
      </Wrapper>
    );
  }
}

export default SettingsNewTeam;