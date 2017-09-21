import React from "react";
import { shape, arrayOf, string } from "prop-types";
import { Alert } from "react-bootstrap";
import { FormattedMessage } from "react-intl";

const InviteUsersResults = props => (
  <div>
    <h5>
      <FormattedMessage id="invite_users.results_title" />
    </h5>
    <hr />
    {props.results.invite_results.map(result => (
      <Alert bsStyle={result.alert} key={result.email}>
        <strong>{result.email}</strong>
        &nbsp;-&nbsp;
        <FormattedMessage
          id={`invite_users.results_msg.${result.status}`}
          values={{
            team: props.results.team_name,
            role: (
              <FormattedMessage id={`invite_users.roles.${result.user_role}`} />
            ),
            nr: result.invite_limit
          }}
        />
      </Alert>
    ))}
  </div>
);

InviteUsersResults.propTypes = {
  results: shape({
    invite_results: arrayOf.isRequired,
    team_name: string.isRequired
  }).isRequired
};

export default InviteUsersResults;
