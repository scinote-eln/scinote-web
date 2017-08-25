import React, { Component } from "react";
import PropTypes, { bool, number, string, func } from "prop-types";
import { Modal, Button, Alert, Glyphicon } from "react-bootstrap";
import { FormattedMessage, FormattedHTMLMessage } from "react-intl";
import { connect } from "react-redux";

import { leaveTeamModalShow } from "../../actions/LeaveTeamActions";

class LeaveTeamModal extends Component {
  constructor(props) {
    super(props);
    this.onCloseModal = this.onCloseModal.bind(this);
  }

  onCloseModal() {
    this.props.leaveTeamModalShow(false);
  }

  render() {
    return (
      <Modal show={this.props.showModal} onHide={this.onCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>
            <FormattedMessage
              id="settings_page.leave_team_modal.title"
              values={{ teamName: this.props.teamName }}
            />
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            <FormattedMessage id="settings_page.leave_team_modal.subtitle" />
          </p>
          <Alert bsStyle="danger">
            <Glyphicon glyph="exclamation-sign" />{" "}
            <FormattedMessage id="settings_page.leave_team_modal.warnings" />
            <ul>
              <li>
                <FormattedMessage id="settings_page.leave_team_modal.warning_message_one" />
              </li>
              <li>
                <FormattedHTMLMessage id="settings_page.leave_team_modal.warning_message_two" />
              </li>
              <li>
                <FormattedMessage id="settings_page.leave_team_modal.warning_message_three" />
              </li>
            </ul>
          </Alert>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={this.onCloseModal}>
            <FormattedMessage id="general.close" />
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

LeaveTeamModal.propTypes = {
  showModal: bool.isRequired,
  teamId: number.isRequired,
  teamName: string.isRequired,
  leaveTeamModalShow: func.isRequired,
  teams: PropTypes.arrayOf(
    PropTypes.shape({
      id: number.isRequired,
      name: string.isRequired,
      current_team: bool.isRequired,
      role: string.isRequired,
      members: number.isRequired
    }).isRequired
  )
};
const mapStateToProps = ({ showLeaveTeamModal }) => ({
  showModal: showLeaveTeamModal.show,
  teamId: showLeaveTeamModal.id,
  teamName: showLeaveTeamModal.teamName
});

export default connect(mapStateToProps, { leaveTeamModalShow })(LeaveTeamModal);
