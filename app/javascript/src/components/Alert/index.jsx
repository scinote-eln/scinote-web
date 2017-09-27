import React, { Component } from "react";
import PropTypes from "prop-types";

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
    const message = this.props.message;
    const alertClassName =
      `alert
       ${Alert.alertClass(message.type)}
       alert-dismissable
       alert-floating
       fade in`;
    const glyphiconClassName =
      `glyphicon
       ${Alert.glyphiconClass(message.type)}`;

    return(
      <div className={alertClassName}>
        <div className="container">
          <button type="button"
                  className="close"
                  data-dismiss="alert"
                  aria-label="Close"
                  onClick={this.props.onClose}
          >
            <span aria-hidden="true">×</span>
          </button>
          <span className={glyphiconClassName} />
          <span>&nbsp;{message.text}</span>
        </div>
      </div>
    );
  }
}

Alert.propTypes = {
  onClose: PropTypes.func,
  timeout: PropTypes.number,
  message: PropTypes.shape({
    type: PropTypes.string.isRequired,
    text: PropTypes.string.isRequired
  }).isRequired
};

Alert.defaultProps = {
  onClose: null,
  timeout: 3000
};

export default Alert;