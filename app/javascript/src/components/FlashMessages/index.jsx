import React, { Component } from "react";
import PropTypes from "prop-types";
import Alert from "./components/Alert";

class FlashMessages extends Component {

  constructor(props) {
    super(props);
    this.state = {
      messages: props.messages
    };
  }

  render () {
    return(
      <div id="notifications">
        {this.state.messages.map(message =>
          <Alert key={message.id} message={message} />)
        }
      </div>
    );
  }
}

FlashMessages.propTypes = {
  messages: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      type: PropTypes.string.isRequired,
      text: PropTypes.string.isRequired
    })
  )
};

FlashMessages.defaultProps = {
  messages: []
}

export default FlashMessages;