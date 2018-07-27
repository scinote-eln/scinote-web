import React, { Component } from "react";
import styled from "styled-components";
import { string, number, func } from "prop-types";
import { Grid, Row, Col } from "react-bootstrap";

const Wrapper = styled.div`
  margin-bottom: 0;
`;

class Alert extends Component {
  static alertClass(type) {
    const classes = {
      error: "alert-danger",
      alert: "alert-warning",
      notice: "alert-info",
      success: "alert-success"
    };
    return classes[type] || classes.success;
  }

  static fasClass(type) {
    const classes = {
      error: "fa-exclamation-circle",
      alert: "fa-exclamation-circle",
      notice: "fa-info-circle",
      success: "fa-check-circle"
    };
    return classes[type] || classes.success;
  }

  componentDidMount() {
    this.timer = setTimeout(
      this.props.onClose,
      this.props.timeout
    );
  }

  componentWillUnmount() {
    clearTimeout(this.timer);
  }

  render() {
    const alertClassName =
      `alert
       ${Alert.alertClass(this.props.type)}
       alert-dismissable
       alert-floating`;
    const fasClassName =
      `fas
       ${Alert.fasClass(this.props.type)}`;

    return (
      <Wrapper className={alertClassName}>
        <Grid>
          <Row>
            <Col>
              <button type="button"
                      className="close"
                      data-dismiss="alert"
                      aria-label="Close"
                      onClick={this.props.onClose}>
                <span aria-hidden="true">×</span>
              </button>
              <span className={fasClassName} />
              <span>&nbsp;{this.props.message}</span>
            </Col>
          </Row>
        </Grid>
      </Wrapper>
    );
  }
}

Alert.propTypes = {
  message: string.isRequired,
  type: string.isRequired,
  timeout: number.isRequired,
  onClose: func.isRequired
};

export default Alert;
