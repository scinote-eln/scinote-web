import React, { Component } from "react";
import styled from "styled-components";
import update from "immutability-helper";
import TransitionGroup from 'react-transition-group/TransitionGroup';
import CSSTransition from 'react-transition-group/CSSTransition';
import Alert from "./components/Alert";

const Wrapper = styled.div`
  position: absolute;
  z-index: 1000;
  width: 100%;
`;

class AlertsContainer extends Component {
  constructor(props) {
    super(props);

    this.state = {
      alerts: []
    };

    this.add = this.add.bind(this);
    this.clearAll = this.clearAll.bind(this);
    this.clear = this.clear.bind(this);
    this.renderAlert = this.renderAlert.bind(this);

    // Bind self to global namespace
    window.alerts = this;
  }

  add(message, type, timeout) {
    this.setState(
      update(
        this.state,
        { alerts: { $push: [{ message, type, timeout }] } }
      )
    );
  }

  clearAll() {
    this.setState({ alerts: [] });
  }

  clear(alert) {
    const index = this.state.alerts.indexOf(alert);
    const alerts = update(this.state.alerts, { $splice: [[index, 1]] });
    this.setState({ alerts: alerts });
  }

  renderAlert(alert) {
    return (
      <Alert message={alert.message}
             type={alert.type}
             timeout={alert.timeout}
             onClose={() => this.clear(alert)}
      />
    );
  }

  render() {
    return (
      <Wrapper>
        <TransitionGroup>
          {this.state.alerts.map((alert, index) =>
            <CSSTransition key={`alert-${index}`}
                           timeout={500}
                           classNames="alert-animated">
              {this.renderAlert(alert, index)}
            </CSSTransition>
          )}
        </TransitionGroup>
      </Wrapper>
    );
  }
}

export default AlertsContainer;