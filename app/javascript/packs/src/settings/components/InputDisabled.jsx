import React from "react";
import { string, func } from "prop-types";
import { FormGroup, FormControl, ControlLabel, Button } from "react-bootstrap";
import styled from "styled-components";

const Wrapper = styled.div`margin-top: 19px;`;

const MyFormControl = styled(FormControl)`
  width: 150px;
  display: inline;
`;

const MyButton = styled(Button)`
  border-radius: 0 50px 50px 0;
  margin-top: -3px;
  margin-left: -3px;
`;

const InputDisabled = props =>
  <Wrapper>
    <form>
      <FormGroup>
        <ControlLabel>
          {props.labelValue}
        </ControlLabel>
        <FormGroup>
          <MyFormControl
            type={props.inputType}
            value={props.inputValue}
            disabled
          />
          <MyButton bsStyle="default" onClick={props.enableEdit}>
            Edit
          </MyButton>
        </FormGroup>
      </FormGroup>
    </form>
  </Wrapper>;

InputDisabled.propTypes = {
  labelValue: string.isRequired,
  inputType: string.isRequired,
  inputValue: string.isRequired,
  enableEdit: func.isRequired
};

export default InputDisabled;
