import React, { Component } from "react";
import { bool } from "prop-types";
import { connect } from "react-redux";
import styled from "styled-components";

const Wrapper = styled.div`
  background-color: rgba(0, 0, 0, 0.2);
  opaciti: 0.5;
  position: absolute;
  top: 0;
  width: 100%;
  height: 100%;
  .center-box {
    height: 80%;
    display: flex;
    align-items: center;
    justify-content: center;
  }
`;

class Spinner extends Component {
  render() {
    let spinner = <div />;
    if (this.props.spinner_on) {
      spinner = (
        <Wrapper>
          <div className="center-box">
            <i className="fa fa-spinner fa-spin fa-3x" aria-hidden="true" />
          </div>
        </Wrapper>
      );
    }

    return spinner;
  }
}

Spinner.propTypes = {
  spinner_on: bool.isRequired
};

const mapStateToProps = state => state.global_activities;

export default connect(mapStateToProps, {})(Spinner);
