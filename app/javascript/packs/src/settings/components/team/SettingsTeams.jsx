import React from "react";
import styled from "styled-components";

import { BORDER_LIGHT_COLOR } from "../../../../app/constants/colors";

const Wrapper = styled.div`
  background: white;
  box-sizing: border-box;
  border: 1px solid ${BORDER_LIGHT_COLOR};
  border-top: none;
  margin: 0;
  padding: 16px 0 50px 0;
`;

const SettingsTeams = () =>
  <Wrapper>
    <h1 className="text-center">Settings Teams</h1>
  </Wrapper>;

export default SettingsTeams;
