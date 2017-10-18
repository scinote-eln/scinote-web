// @flow
import React, { Component } from "react";
import { connect } from "react-redux";
import {
  Breadcrumb,
  FormGroup,
  FormControl,
  ControlLabel,
  HelpBlock,
  Button,
  ButtonToolbar
} from "react-bootstrap";
import { Redirect } from "react-router-dom";
import { LinkContainer } from "react-router-bootstrap";
import { FormattedMessage } from "react-intl";
import update from "immutability-helper";
import styled from "styled-components";
import _ from "lodash";
import type { Teams$NewTeam } from "flow-typed";
import { createNewTeam } from "../../../../../services/api/teams_api";
import {
  SETTINGS_TEAMS_ROUTE,
  SETTINGS_TEAM_ROUTE
} from "../../../../../config/routes";

import {
  NAME_MIN_LENGTH,
  NAME_MAX_LENGTH,
  TEXT_MAX_LENGTH
} from "../../../../../config/constants/numeric";
import { getTeamsList } from "../../../../../components/actions/TeamsActions";

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

const MyFormGroupDiv = styled.div`
  margin-bottom: 15px;
`;

type Props = {
  tabState: Function,
  getTeamsList: Function
};

type FormErrors = {
  name: string,
  description: string
};

type State = {
  team: Teams$NewTeam,
  formErrors: FormErrors,
  redirectTo: string
};

class SettingsNewTeam extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      team: {
        name: "",
        description: ""
      },
      formErrors: {
        name: "",
        description: ""
      },
      redirectTo: ""
    };

    (this: any).onSubmit = this.onSubmit.bind(this);
    (this: any).validateField = this.validateField.bind(this);
    (this: any).handleChange = this.handleChange.bind(this);
    (this: any).renderTeamNameFormGroup = this.renderTeamNameFormGroup.bind(
      this
    );
    (this: any).renderTeamDescriptionFormGroup = this.renderTeamDescriptionFormGroup.bind(
      this
    );
  }

  componentDidMount(): void {
    this.props.tabState("2");
  }

  onSubmit(e: SyntheticEvent<HTMLInputElement>): void {
    e.preventDefault();
    createNewTeam(this.state.team)
      .then(response => {
        // Redirect to the new team page
        this.props.getTeamsList();
        (this: any).newState = { ...this.state };
        (this: any).newState = update((this: any).newState, {
          redirectTo: {
            $set: SETTINGS_TEAM_ROUTE.replace(":id", response.details.id)
          }
        });
        (this: any).setState((this: any).newState);
      })
      .catch(er => {
        // Display errors
        (this: any).newState = { ...this.state };
        ["name", "description"].forEach(el => {
          if (er.response.data.details[el]) {
            (this: any).newState = update((this: any).newState, {
              formErrors: {
                name: { $set: <span>{er.response.data.details[el]}</span> }
              }
            });
          }
        });
        (this: any).setState((this: any).newState);
      });
  }

  validateField(key: string, value: string) {
    let errorMessage;
    if (key === "name") {
      errorMessage = "";

      if (value.length < NAME_MIN_LENGTH) {
        errorMessage = (
          <FormattedMessage
            id="error_messages.text_too_short"
            values={{ min_length: NAME_MIN_LENGTH }}
          />
        );
      } else if (value.length > NAME_MAX_LENGTH) {
        errorMessage = (
          <FormattedMessage
            id="error_messages.text_too_long"
            values={{ max_length: NAME_MAX_LENGTH }}
          />
        );
      }

      (this: any).newState = update((this: any).newState, {
        formErrors: { name: { $set: errorMessage } }
      });
    } else if (key === "description") {
      errorMessage = "";

      if (value.length > TEXT_MAX_LENGTH) {
        errorMessage = (
          <FormattedMessage
            id="error_messages.text_too_long"
            values={{ max_length: TEXT_MAX_LENGTH }}
          />
        );
      }

      (this: any).newState = update((this: any).newState, {
        formErrors: { description: { $set: errorMessage } }
      });
    }
  }

  handleChange(e: SyntheticInputEvent<HTMLInputElement>): void {
    const key = e.target.name;
    const value = e.target.value;

    (this: any).newState = { ...this.state };

    // Update value in the state
    (this: any).newState = update((this: any).newState, {
      team: { [key]: { $set: value } }
    });

    // Validate the input
    (this: any).validateField(key, value);

    // Refresh state
    (this: any).setState((this: any).newState);
  }

  renderTeamNameFormGroup() {
    const formGroupClass = this.state.formErrors.name
      ? "form-group has-error"
      : "form-group";
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
    const formGroupClass = this.state.formErrors.description
      ? "form-group has-error"
      : "form-group";
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

    const btnDisabled =
      !_.isEmpty(this.state.formErrors.name) ||
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
          <MyFormGroupDiv>
            {this.renderTeamNameFormGroup()}
            <small>
              <FormattedMessage id="settings_page.new_team.name_sublabel" />
            </small>
          </MyFormGroupDiv>

          <MyFormGroupDiv>
            {this.renderTeamDescriptionFormGroup()}
            <small>
              <FormattedMessage id="settings_page.new_team.description_sublabel" />
            </small>
          </MyFormGroupDiv>
          <ButtonToolbar>
            <Button
              type="submit"
              className="btn-primary"
              disabled={btnDisabled}
            >
              <FormattedMessage id="settings_page.new_team.create" />
            </Button>
            <LinkContainer to={SETTINGS_TEAMS_ROUTE}>
              <Button>
                <FormattedMessage id="general.cancel" />
              </Button>
            </LinkContainer>
          </ButtonToolbar>
        </form>
      </Wrapper>
    );
  }
}

export default connect(null, { getTeamsList })(SettingsNewTeam);
