// @flow

import React from "react";
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

export default (props: { spinner_on: boolean }) => {
  let spinner = <div />;
  if (props.spinner_on) {
    spinner = (
      <Wrapper>
        <div className="center-box">
          <i className="fas fa-spinner fa-spin fa-3x" aria-hidden="true" />
        </div>
      </Wrapper>
    );
  }
  return spinner;
};
