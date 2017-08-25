import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import { FormattedMessage } from "react-intl";
import { Modal, Button } from "react-bootstrap";
import _ from "lodash";
import styled from "styled-components";

import { getActivities } from "../../actions/ActivitiesActions";
import ActivityElement from "./ActivityElement";
import ActivityDateElement from "./ActivityDateElement";
import {
  WHITE_COLOR,
  COLOR_CONCRETE,
  COLOR_MINE_SHAFT,
  COLOR_GRAY_LIGHT_YADCF
} from "../../../app/constants/colors";

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
  color: ${COLOR_MINE_SHAFT};;
`;

class GlobalActivitiesModal extends Component {
  constructor(props) {
    super(props);
    this.displayActivities = this.displayActivities.bind(this);
    this.addMoreActivities = this.addMoreActivities.bind(this);
  }

  displayActivities() {
    if (this.props.activities.length === 0) {
      return (
        <li>
          <FormattedMessage id="activities.no_data" />
        </li>
      );
    }
    return this.props.activities.map((activity, i, arr) => {
      const newDate = new Date(activity.created_at);
      if (i > 0) {
        const prevDate = new Date(arr[i - 1].created_at);
        if (prevDate < newDate) {
          return [
            <ActivityDateElement key={newDate} date={newDate} />,
            <ActivityElement key={activity.id} activity={activity} />
          ];
        }
      } else {
        return [
          <ActivityDateElement key={newDate} date={newDate} />,
          <ActivityElement key={activity.id} activity={activity} />
        ];
      }
      return <ActivityElement key={activity.id} activity={activity} />;
    });
  }

  addMoreActivities() {
    const lastId = _.last(this.props.activities).id;
    this.props.fetchActivities(lastId);
  }

  addMoreButton() {
    if (this.props.more) {
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
      <Modal show={this.props.showModal} onHide={this.props.onCloseModal}>
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
          <Button onClick={this.props.onCloseModal}>
            <FormattedMessage id="general.close" />
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

GlobalActivitiesModal.propTypes = {
  showModal: PropTypes.bool.isRequired,
  onCloseModal: PropTypes.func.isRequired,
  fetchActivities: PropTypes.func.isRequired,
  more: PropTypes.bool.isRequired,
  activities: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      message: PropTypes.string.isRequired,
      created_at: PropTypes.string.isRequired
    })
  ).isRequired
};

const mapStateToProps = ({ global_activities }) => {
  const { activities, more } = global_activities;
  return { activities, more };
};

const mapDispatchToProps = dispatch => ({
  fetchActivities(lastId) {
    dispatch(getActivities(lastId));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(
  GlobalActivitiesModal
);
