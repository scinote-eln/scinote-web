import React, { Component } from "react";
import PropTypes from "prop-types";

class NotificationsSwitch extends Component {
  constructor(props) {
    super(props);

    this.handleClick = this.handleClick.bind(this);
  }

  handleClick() {
    if (!this.props.isDisabled) {
      this.props.toggleSwitch();
    }
  }

  render() {
    let switchBtn;

    if (this.props.isSwitchOn) {
      switchBtn = (
        <div className="btn-group">
          <button
            className="btn btn-default"
            disabled={this.props.isDisabled}
            onClick={this.handleClick}
          >
            No
          </button>
          <button
            className="btn btn-primary"
            disabled={this.props.isDisabled}
            onClick={this.handleClick}
          >
            Yes
          </button>
        </div>
      );
    } else {
      switchBtn = (
        <div className="btn-group">
          <button
            className="btn btn-danger"
            disabled={this.props.isDisabled}
            onClick={this.handleClick}
          >
            No
          </button>
          <button
            className="btn btn-default"
            disabled={this.props.isDisabled}
            onClick={this.handleClick}
          >
            Yes
          </button>
        </div>
      );
    }

    return (
      <div className="row">
        <div className="col-sm-4">
          {this.props.title}
        </div>
        <div className="col-sm-8">
          {switchBtn}
        </div>
      </div>
    );
  }
}

NotificationsSwitch.propTypes = {
  title: PropTypes.string.isRequired,
  isSwitchOn: PropTypes.bool.isRequired,
  isDisabled: PropTypes.bool.isRequired,
  toggleSwitch: PropTypes.func.isRequired
};

export default NotificationsSwitch;
