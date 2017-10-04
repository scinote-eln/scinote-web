// @flow

import React, { Component } from "react";
import { FormattedMessage } from "react-intl";
import { Modal, Button } from "react-bootstrap";
import _ from "lodash";
import styled from "styled-components";

import { getActivities } from "../../../services/api/activities_api";
import ActivityElement from "./ActivityElement";
import ActivityDateElement from "./ActivityDateElement";
import {
  WHITE_COLOR,
  COLOR_CONCRETE,
  COLOR_MINE_SHAFT,
  COLOR_GRAY_LIGHT_YADCF
} from "../../../config/constants/colors";

const StyledBottom = styled(Button)`
  display: inline-block;
  margin-bottom: 0;
  font-weight: normal;
  text-align: center;
  vertical-align: middle;
  touch-action: manipulation;
  cursor: pointer;
  background-image: none;
  border: 1px solid transparent;
  white-space: nowrap;
  padding: 6px 12px;
  font-size: 14px;
  line-height: 1.42857143;
  border-radius: 4px;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  color: ${COLOR_MINE_SHAFT};
  background-color: ${WHITE_COLOR};
  border-color: ${COLOR_GRAY_LIGHT_YADCF};
`;

const StyledModalBody = styled(Modal.Body)`
  background-color: ${COLOR_CONCRETE};
  color: ${COLOR_MINE_SHAFT};
`;

type Props = {
  more: boolean,
  showModal: boolean,
  onCloseModal: Function,
  activites: Array<Activity>
};

type State = {
  activities: Array<Activity>,
  more: boolean
};

class GlobalActivitiesModal extends Component<Props, State> {
  displayActivities: Function;
  addMoreActivities: Function;
  loadData: Function;
  onCloseModalActions: Function;

  constructor(props: Props) {
    super(props);
    this.state = { activities: [], more: false };
    this.displayActivities = this.displayActivities.bind(this);
    this.addMoreActivities = this.addMoreActivities.bind(this);
    this.onCloseModalActions = this.onCloseModalActions.bind(this);
    this.loadData = this.loadData.bind(this);
  }

  loadData() {
    getActivities().then(response => {
      this.setState({
        activities: response.activities,
        more: response.more
      });
    });
  }

  onCloseModalActions() {
    this.setState({ activities: [], more: false });
    this.props.onCloseModal();
  }

  displayActivities() {
    if (this.state.activities.length === 0) {
      if (this.props.showModal) {
        this.loadData();
      }

      return (
        <li>
          <FormattedMessage id="activities.no_data" />
        </li>
      );
    }
    return this.state.activities.map((activity, i, arr) => {
      const dateNow = new Date();
      const newDate = new Date(activity.created_at);
      if (i > 0) {
        const prevDate = new Date(arr[i - 1].created_at);
        if (prevDate.getDate() > newDate.getDate()) {
          return [
            <ActivityDateElement key={newDate} date={newDate} />,
            <ActivityElement key={i} activity={activity} />
          ];
        }
      } else {
        if (
          newDate.getDate() === dateNow.getDate() &&
          newDate.getMonth() === dateNow.getMonth() &&
          newDate.getFullYear() === dateNow.getFullYear()
        ) {
          return [
            <ActivityDateElement key={newDate} date={newDate} today />,
            <ActivityElement key={i} activity={activity} />
          ];
        }
        return [
          <ActivityDateElement key={newDate} date={newDate} />,
          <ActivityElement key={i} activity={activity} />
        ];
      }
      console.log("banana");
      return <ActivityElement key={i} activity={activity} />;
    });
  }

  addMoreActivities() {
    const lastId = _.last(this.state.activities).id;
    getActivities(
      lastId
    ).then((response: { activities: Array<Activity>, more: boolean }) => {
      this.setState({
        activities: [...this.state.activities, ...response.activities],
        more: response.more
      });
    });
  }

  addMoreButton() {
    if (this.state.more) {
      return (
        <li className="text-center">
          <StyledBottom onClick={this.addMoreActivities}>
            <FormattedMessage id="activities.more_activities" />
          </StyledBottom>
        </li>
      );
    }
    return "";
  }

  render() {
    return (
      <Modal show={this.props.showModal} onHide={this.onCloseModalActions}>
        <Modal.Header closeButton>
          <Modal.Title>
            <FormattedMessage id="activities.modal_title" />
          </Modal.Title>
        </Modal.Header>
        <StyledModalBody>
          <ul className="list-unstyled">
            {this.displayActivities()}
            {this.addMoreButton()}
          </ul>
        </StyledModalBody>
        <Modal.Footer>
          <Button onClick={this.onCloseModalActions}>
            <FormattedMessage id="general.close" />
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

export default GlobalActivitiesModal;
