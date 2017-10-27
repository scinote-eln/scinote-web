// @flow
import React, { Component } from "react";
import { connect } from "react-redux";
import {
  Breadcrumb,
  FormControl,
  ControlLabel,
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
import { getTeamsList } from "../../../../../components/actions/TeamsActions";
import {
  ValidatedForm,
  ValidatedFormGroup,
  ValidatedFormControl,
  ValidatedErrorHelpBlock,
  ValidatedSubmitButton
} from "../../../../../components/validation";
import {
  nameLengthValidator,
  textMaxLengthValidator

} from "../../../../../components/validation/validators/text";

import { BORDER_LIGHT_COLOR } from "../../../../../config/constants/colors";

import PageTitle from "../../../../../components/PageTitle";
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

type State = {
  team: Teams$NewTeam,
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
      redirectTo: ""
    };

    (this: any).onSubmit = this.onSubmit.bind(this);
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

        const newState = update((this: any).state, {
          redirectTo: {
            $set: SETTINGS_TEAM_ROUTE.replace(":id", response.details.id)
          }
        });
        (this: any).setState(newState);
      })
      .catch(er => {
        // Display errors
        (this: any).newTeamForm.setErrors(er.response.data.details);
      });
  }

  handleChange(e: SyntheticInputEvent<HTMLInputElement>, tag: string): void {
    const value = e.target.value;

    const newState = update((this: any).state, {
      team: { [tag]: { $set: value } }
    });
    (this: any).setState(newState);
  }

  renderTeamNameFormGroup() {
    return (
      <ValidatedFormGroup tag="name">
        <ControlLabel>
          <FormattedMessage id="settings_page.new_team.name_label" />
        </ControlLabel>
        <NameFormControl
          value={this.state.team.name}
          tag="name"
          validatorsOnChange={[nameLengthValidator]}
          onChange={(e) => this.handleChange(e, "name")}
        />
        <FormControl.Feedback />
        <ValidatedErrorHelpBlock tag="name" />
      </ValidatedFormGroup>
    );
  }

  renderTeamDescriptionFormGroup() {
    return (
      <ValidatedFormGroup tag="description">
        <ControlLabel>
          <FormattedMessage id="settings_page.new_team.description_label" />
        </ControlLabel>
        <ValidatedFormControl
          componentClass="textarea"
          value={this.state.team.description}
          tag="description"
          validatorsOnChange={[textMaxLengthValidator]}
          onChange={(e) => this.handleChange(e, "description")}
        />
        <ValidatedErrorHelpBlock tag="description" />
      </ValidatedFormGroup>
    );
  }

  render() {
    // Redirect if form successful
    if (!_.isEmpty(this.state.redirectTo)) {
      return <Redirect to={this.state.redirectTo} />;
    }

    return (
      <PageTitle localeID="page_title.new_team_page">
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

          <ValidatedForm
            onSubmit={this.onSubmit}
            ref={(f) => { (this: any).newTeamForm = f; }}
            style={{ maxWidth: "500px" }}
          >
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
              <ValidatedSubmitButton
                type="submit"
                className="btn-primary"
              >
                <FormattedMessage id="settings_page.new_team.create" />
              </ValidatedSubmitButton>
              <LinkContainer to={SETTINGS_TEAMS_ROUTE}>
                <Button>
                  <FormattedMessage id="general.cancel" />
                </Button>
              </LinkContainer>
            </ButtonToolbar>
          </ValidatedForm>
        </Wrapper>
      </PageTitle>
    );
  }
}

export default connect(null, { getTeamsList })(SettingsNewTeam);
