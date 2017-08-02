import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import { FormattedMessage } from "react-intl";
import { Modal, Button } from "react-bootstrap";
import _ from "lodash";

import { getActivities } from "../../actions/ActivitiesActions";
import ActivityElement from "./ActivityElement";
import ActivityDateElement from "./ActivityDateElement";

class GlobalActivitiesModal extends Component {
  constructor(props) {
    super(props);
    this.displayActivities = this.displayActivities.bind(this);
    this.addMoreActivities = this.addMoreActivities.bind(this);
  }

  displayActivities() {
    console.log(this.props.global_activities);
    if (this.props.global_activities.length === 0) {
      return (
        <li>
          <FormattedMessage id="activities.no_data" />
        </li>
      );
    }
    return this.props.global_activities.map((activity, i, arr) => {
      let newDate = new Date(activity.created_at);
      if (i > 0) {
        let prevDate = new Date(arr[i - 1].created_at);
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
    let last_id = _.last(this.props.global_activities).id;
    this.props.fetchActivities(last_id);
  }

  addMoreButton() {
    console.log(this.props.more_global_activities);
    if(this.props.more_global_activities) {
      return (
        <li>
          <Button onClick={this.addMoreActivities}>
            <FormattedMessage id="activities.more_activities" />
          </Button>
        </li>
      );
    }
  }

  render() {
    return (
      <Modal show={this.props.showModal} onHide={this.props.onCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>
            <FormattedMessage id="activities.modal_title" />
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <ul>
            {this.displayActivities()}
            {this.addMoreButton()}
          </ul>
        </Modal.Body>
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
  more_global_activities: PropTypes.bool.isRequired,
  global_activities: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      message: PropTypes.string.isRequired,
      created_at: PropTypes.string.isRequired
    })
  ).isRequired
};

const mapStateToProps = ({ global_activities, more_global_activities }) => {
  return { global_activities, more_global_activities };
};

const mapDispatchToProps = dispatch => ({
  fetchActivities(last_id) {
    dispatch(getActivities(last_id));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(
  GlobalActivitiesModal
);
