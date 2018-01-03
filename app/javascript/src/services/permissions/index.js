// @flow
/*
 To use this HOC you need to import in you targeted component:

 > import * as Permissions from "relative path../services/permissions"

 Than you use the Permissions.connect method to wrap your component and
 pass this "permissions helper methods" in your component params:

 >
 > Permissions.connect(MyComponent, ["can_update_team?", "can_read_team?"], "Team");
 >

 Now you can access your permissions through component params. The permissions
 you required have 3 states [true, false, null]. Null is when you are waiting for server response.
 You can use methods params.can_update_team? or whatever permissions you declare
*/
import * as React from "react";
import { getPermissionStatus } from "../api/permissions_api";

type State = {
  permissions: any
};

type PermissionsObject = {
  [string]: boolean | null
}
/*
 This function accepts 3 arguments which are REQUIRED
 1.) WrappedComponent: Component that you want to have permissions
 2.) requiredPermissions: an array of strings with permissions methods that
     will be available in your component
 3.) resource: a string of reference/model name
*/
export function connect<Props: {}>(
  WrappedComponent: React.ComponentType<Props>,
  requiredPermissions: Array<string> = [],
  resource: string
) {
  const parsedPermissions: PermissionsObject = {};
  requiredPermissions.forEach(el => {
    parsedPermissions[el] = null;
  });

  return class extends React.Component<*, State> {
    constructor(props: any) {
      super(props);
      this.state = { permissions: parsedPermissions };
    }

    componentDidMount(): void {
      getPermissionStatus(requiredPermissions, resource)
        .then(data => {
          this.setState({ permissions: data });
        })
        .catch(() => {
          const permissions: PermissionsObject = {};
          requiredPermissions.forEach(el => {
            permissions[el] = false;
          });
          this.setState({ permissions });
        });
    }

    render(): any {
      return (
        <WrappedComponent
          permissions={this.state.permissions}
          {...this.props}
        />
      );
    }
  };
}
