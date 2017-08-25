import React, { Component } from "react";
import { Modal, Button } from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import { connect } from "react-redux";

class LeaveTeamModal extends Component {
  render() {
    return (
      <Modal show={this.props.showModal}>
        <Modal.Header closeButton>
          <Modal.Title>
            <FormattedMessage id="activities.modal_title" />
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

const mapStateToProps = ({ showLeaveTeamModal }) => ({
  showModal: showLeaveTeamModal.show,
  teamId: showLeaveTeamModal.id
});

export default connect(mapStateToProps)(LeaveTeamModal);
