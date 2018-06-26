// @flow

import React, { Component } from "react";
import type { Element, Node } from "react";
import { FormattedMessage } from "react-intl";
import { Button, Modal } from "react-bootstrap";
import _ from "lodash";
import styled from "styled-components";
import moment from "moment-timezone";

import { getActivities } from "../../../services/api/activities_api";
import ActivityElement from "./ActivityElement";
import ActivityDateElement from "./ActivityDateElement";
import {
  WHITE_COLOR,
  COLOR_CONCRETE,
  COLOR_EMPEROR,
  COLOR_ALTO
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
  color: ${COLOR_EMPEROR};
  background-color: ${WHITE_COLOR};
  border-color: ${COLOR_ALTO};
`;

const StyledModalBody = styled(Modal.Body)`
  background-color: ${COLOR_CONCRETE};
  color: ${COLOR_EMPEROR};
`;

type Props = {
  showModal: boolean,
  onCloseModal: Function
};

type State = {
  activities: Array<Activity>,
  more: boolean,
  currentPage: number
};

class GlobalActivitiesModal extends Component<Props, State> {
  static renderActivityDateElement(
    key: number,
    activity: Activity,
    date: Date
  ): Node {
    return [
      <ActivityDateElement
        key={date}
        date={date}
        timezone={activity.timezone}
      />,
      <ActivityElement key={key} activity={activity} />
    ];
  }

  constructor(props: Props) {
    super(props);
    this.state = { activities: [], more: false, currentPage: 1 };
    (this: any).displayActivities = this.displayActivities.bind(this);
    (this: any).addMoreActivities = this.addMoreActivities.bind(this);
    (this: any).onCloseModalActions = this.onCloseModalActions.bind(this);
    (this: any).loadData = this.loadData.bind(this);
    (this: any).mapActivities = this.mapActivities.bind(this);
  }

  onCloseModalActions(): void {
    this.setState({ activities: [], more: false, currentPage: 1 });
    this.props.onCloseModal();
  }

  loadData(): void {
    getActivities().then(response => {
      this.setState({
        activities: response.activities,
        more: response.more,
        currentPage: response.currentPage
      });
    });
  }

  mapActivities(): Array<*> {
    return this.state.activities.map(
      (activity: Activity, i: number, arr: Array<*>) => {
        const newDate = new Date(activity.createdAt);
        // returns a label with "today" if the date of the activity is today
        if (i === 0) {
          return GlobalActivitiesModal.renderActivityDateElement(
            activity.id,
            activity,
            newDate
          );
        }
        // check dates based on user timezone value
        const parsePrevDate = moment(arr[i - 1].createdAt)
          .tz(activity.timezone)
          .format( "DD/MM/YYYY")
          .valueOf('day');
        const parseNewDate = moment(activity.createdAt)
          .tz(activity.timezone)
          .format( "DD/MM/YYYY")
          .valueOf();
        if (parsePrevDate > parseNewDate) {
          return GlobalActivitiesModal.renderActivityDateElement(
            activity.id,
            activity,
            newDate
          );
        }
        // returns the default activity element
        return <ActivityElement key={activity.id} activity={activity} />;
      }
    );
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
    return this.mapActivities();
  }

  addMoreActivities(): void {
    getActivities(
      this.state.currentPage + 1
    ).then(
      (response: {
        activities: Array<Activity>,
        more: boolean,
        currentPage: number
      }) => {
        this.setState({
          activities: [...this.state.activities, ...response.activities],
          more: response.more,
          currentPage: response.currentPage
        });
      }
    );
  }

  addMoreButton(): Element<*> {
    if (this.state.more) {
      return (
        <li className="text-center">
          <StyledBottom onClick={this.addMoreActivities}>
            <FormattedMessage id="activities.more_activities" />
          </StyledBottom>
        </li>
      );
    }
    return <span />;
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
