// @flow
/*
 To use this HOC you need to import in you targeted component:

 > import * as Permissions from "relative path../services/permissions"

 Than you use the Permissions.connect method to wrap your component and
 pass this "permissions helper methods" in your component params:

 If you need to specific model you have to specify it in the connect method
 like the example below:
 >
 > Permissions.connect(MyComponent, ["can_update_team", "can_read_team"], "Team");
 >

 In case your component is connected to Redux or some other HOC you can simply
 chain the HOC's:
 >
 > const mapStateToProps = ({ current_team }) => ({ current_team });
 > const MyComponentWithPermissions = Permissions.connect(MyComponent, ["can_read_team"], "Team");
 > export default connect(mapStateToProps)(MyComponentWithPermissions);
 >
 Beside the permissions object there's also the setPermissionResourceId/1 function in your component props.
 This function should be used to pass the ID of the resource when you have it.

 Example: you need the current team for whatever reason you can call it in the
 shouldComponentUpdate function...

 > shouldComponentUpdate(nextProps: any, nextState: any) {
 >   this.props.setPermissionResourceId(this.props.current_team.id);
 >   return true; // remember to return true!
 > }

 JUST REMEMBER THAT YOU HAVE TO PASS A VALID ID and you have to check if it's present at the moment of the execution.
 THE REQUEST WILL BE TRIGGERED WHEN YOU INVOKE setPermissionResourceId/1 FUNCTION!!!

 Otherwise (generic permissions without the accessed object) you can just pass the permissions on the user
 >
 > Permissions.connect(MyComponent, ["can_update"])
 >
 THE REQUEST WILL BE TRIGGERED WHEN THE COMPONENT MOUNTS!!!

 Now you can access your permissions through component params. The permissions
 you required have 3 states [true, false, null]. Null is when you are waiting for server response.

 Finally you can access your permissions in the component using props.permissions.can_... whatever you specify.
 The props.permissions is basically an object that holds all required permissions.
*/

import * as React from "react";
import { getPermissionStatus } from "../api/permissions_api";

type State = {
  permissions: any
};

type ResourceObject = {
  type: string,
  id: number
};

type PermissionsObject = {
  [string]: boolean | null
};
/*
 This function accepts 3 arguments which are REQUIRED
 1.) @WrappedComponent: Component that you want to have permissions
 2.) @requiredPermissions: an array of strings with permissions methods that
     will be available in your component
 3.) @resource: a string of reference/model name
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
      this.state = {
        permissions: parsedPermissions,
        permissionsRequestDone: false
      };
      (this: any).getPermissions = this.getPermissions.bind(this);
      (this: any).setPermissionResourceId = this.setPermissionResourceId.bind(
        this
      );
    }

    componentDidMount(): void {
      if (!resource) {
        this.getPermissions(requiredPermissions, resource);
      }
    }

    setPermissionResourceId(id: number): void {
      this.getPermissions(requiredPermissions, { type: resource, id });
    }

    getPermissions(
      permissionsArray: Array<string>,
      resourceObject: ResourceObject | undefined
    ): void {
      if (!this.state.permissionsRequestDone) {
        getPermissionStatus(permissionsArray, resourceObject)
          .then(data => {
            this.setState({ permissions: data, permissionsRequestDone: true });
          })
          .catch(() => {
            const permissions: PermissionsObject = {};
            permissionsArray.forEach(el => {
              permissions[el] = false;
            });
            this.setState({ permissions });
          });
      }
    }

    render(): any {
      return (
        <WrappedComponent
          permissions={this.state.permissions}
          setPermissionResourceId={
            resource ? this.setPermissionResourceId : undefined
          }
          {...this.props}
        />
      );
    }
  };
}
