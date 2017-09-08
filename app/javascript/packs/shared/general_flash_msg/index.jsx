import React, { Component } from "react";
import PropTypes from "prop-types";
import styled from "styled-components";
import { connect } from "react-redux";

import { closeFlashMsg, showFlashMsg } from "../actions/ActivitiesActions";

const Wrapper = styled.div`margin-top: -20px;`;
const OkSign = styled.span`padding-right: 5px;`;

class GeneralFlashMsg extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    const text = this.props.flash_msg.text;
    const type = this.props.flash_msg.type;
    const isEnabled = this.props.flash_msg.isEnabled;
    let icon = "ok-sign";

    if (type === "danger" || type === "info") {
      icon = "exclamation-sign";
    }

    let flashHtml = <span />;

    if (isEnabled) {
      flashHtml = (
        <Wrapper
          className={`alert alert-${type} alert-dismissable alert-floating`}
        >
          <div className="container">
            <button
              type="button"
              className="close"
              data-dismiss="alert"
              aria-label="Close"
            >
              <span
                aria-hidden="true"
                onClick={() => this.props.closeFlashMsg()}
              >
                ×
              </span>
            </button>
            <OkSign className={`glyphicon glyphicon-${icon}`} />
            <span>
              {text}
            </span>
          </div>
        </Wrapper>
      );
    }

    return flashHtml;
  }
}

GeneralFlashMsg.propTypes = {
  closeFlashMsg: PropTypes.func.isRequired,
  flash_msg: PropTypes.shape({
    text: PropTypes.string.isRequired,
    type: PropTypes.string.isRequired,
    isEnabled: PropTypes.bool.isRequired
  }).isRequired
};

const mapStateToProps = state => state.global_activities;
const mapDispatchToProps = dispatch => ({
  closeFlashMsg() {
    dispatch(closeFlashMsg());
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(GeneralFlashMsg);
