import React, { Component } from "react";
import { connect } from "react-redux";
import styled from "styled-components";
import TransitionGroup from 'react-transition-group/TransitionGroup';
import CSSTransition from 'react-transition-group/CSSTransition';
import { shape, arrayOf, string, number, func } from "prop-types";
import { clearAlert } from "../actions/AlertsActions";
import Alert from "./components/Alert";

const Wrapper = styled.div`
  position: absolute;
  z-index: 1000;
  width: 100%;
`;

class AlertsContainer extends Component {
  constructor(props) {
    super(props);

    this.renderAlert = this.renderAlert.bind(this);
  }

  renderAlert(alert) {
    return (
      <Alert message={alert.message}
             type={alert.type}
             timeout={alert.timeout}
             onClose={() => this.props.clearAlert(alert.id)}
      />
    );
  }

  render() {
    return (
      <Wrapper>
        <TransitionGroup>
          {this.props.alerts.map((alert) =>
            <CSSTransition key={alert.id}
                           timeout={500}
                           classNames="alert-animated">
              {this.renderAlert(alert)}
            </CSSTransition>
          )}
        </TransitionGroup>
      </Wrapper>
    );
  }
}

AlertsContainer.propTypes = {
  alerts: arrayOf(
    shape({
      message: string.isRequired,
      type: string.isRequired,
      id: string.isRequired,
      timeout: number,
      onClose: func
    }).isRequired
  ).isRequired,
  clearAlert: func.isRequired
}

const mapStateToProps = ({ alerts }) => ({ alerts });

export default connect(mapStateToProps, { clearAlert })(AlertsContainer);
