import React from "react";
import { string, func } from "prop-types";
import { FormGroup, FormControl, ControlLabel, Button } from "react-bootstrap";

const InputDisabled = props =>
  <form>
    <FormGroup>
      <ControlLabel>
        {props.labelValue}
      </ControlLabel>
      <FormControl type={props.inputType} value={props.inputValue} disabled />
      <Button bsStyle="default" onClick={props.enableEdit}>
        Edit
      </Button>
    </FormGroup>
  </form>;

InputDisabled.propTypes = {
  labelValue: string.isRequired,
  inputType: string.isRequired,
  inputValue: string.isRequired,
  enableEdit: func.isRequired
};

export default InputDisabled;
