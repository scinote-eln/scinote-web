import React, { Component } from "react";
import styled from "styled-components";
import PropTypes from "prop-types";
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

  static glyphiconClass(type) {
    const classes = {
      error: "glyphicon-exclamation-sign",
      alert: "glyphicon-exclamation-sign",
      notice: "glyphicon-info-sign",
      success: "glyphicon-ok-sign"
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
    const glyphiconClassName =
      `glyphicon
       ${Alert.glyphiconClass(this.props.type)}`;

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
              <span className={glyphiconClassName} />
              <span>&nbsp;{this.props.message}</span>
            </Col>
          </Row>
        </Grid>
      </Wrapper>
    );
  }
}

Alert.propTypes = {
  message: PropTypes.string.isRequired,
  type: PropTypes.string.isRequired,
  timeout: PropTypes.number,
  onClose: PropTypes.func
};

Alert.defaultProps = {
  timeout: 5000,
  onClose: undefined
};

export default Alert;