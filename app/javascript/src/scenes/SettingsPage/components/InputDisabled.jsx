import React from "react";
import { string, func } from "prop-types";
import { FormGroup, FormControl, ControlLabel, Button } from "react-bootstrap";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";
import { transformName } from "../../../services/helpers/string_helper";

const Wrapper = styled.div`
  margin-top: 19px;
`;

const MyFormControl = styled(FormControl)`
  width: 160px;
  display: inline;
`;

const MyButton = styled(Button)`
  border-radius: 0 50px 50px 0;
  margin-top: -3px;
  margin-left: -3px;
`;

const InputDisabled = props => (
  <Wrapper>
    <form>
      <FormGroup id={transformName(props.labelTitle)}>
        <ControlLabel>
          <FormattedMessage id={props.labelTitle} />
        </ControlLabel>
        <FormGroup>
          <MyFormControl
            type={props.inputType}
            value={props.inputValue}
            disabled
          />
          <MyButton bsStyle="default" onClick={props.enableEdit}>
            <FormattedMessage id="general.edit" />
          </MyButton>
        </FormGroup>
      </FormGroup>
    </form>
  </Wrapper>
);

InputDisabled.defaultProps = {
  inputValue: ""
};

InputDisabled.propTypes = {
  labelTitle: string.isRequired,
  inputType: string.isRequired,
  inputValue: string.isRequired,
  enableEdit: func.isRequired
};

export default InputDisabled;
