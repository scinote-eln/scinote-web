import React, { Component } from "react";
import PropTypes, { bool, number, string } from "prop-types";
import { Modal, Button } from "react-bootstrap";
import _ from "lodash";
import { FormattedMessage } from "react-intl";
import { connect } from "react-redux";

class LeaveTeamModal extends Component {

  render() {
    return (
      <Modal show={this.props.showModal}>
        <Modal.Header closeButton>
          <Modal.Title>
            <FormattedMessage
              id="settings_page.leave_team_modal.title"
              values={{ teamName: this.props.teamName }}
            />
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>BANANAN</Modal.Body>
        <Modal.Footer>
          <Button>
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
  teams: PropTypes.arrayOf(
    PropTypes.shape({
      id: number.isRequired,
      name: string.isRequired,
      current_team: bool.isRequired,
      role: string.isRequired,
      members: number.isRequired,
    }).isRequired
  )
};
const mapStateToProps = ({ showLeaveTeamModal }) => ({
  showModal: showLeaveTeamModal.show,
  teamId: showLeaveTeamModal.id,
  teamName: showLeaveTeamModal.teamName
});

export default connect(mapStateToProps)(LeaveTeamModal);
