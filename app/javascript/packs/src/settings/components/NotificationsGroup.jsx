import React, { Component } from "react";
import PropTypes from "prop-types";
import styled from "styled-components";

import NotificationsSwitchGroup from "./NotificationsSwitchGroup";
import { WHITE_COLOR } from "../../../app/constants/colors";

const Wrapper = styled.div`margin-bottom: 6px;`;

const IconWrapper = styled.div`
  margin-top: 12px;
  margin-left: 7px;
`;

const Icon = styled.span`
  border-radius: 50%;
  color: ${WHITE_COLOR};
  display: block;
  font-size: 15px;
  height: 30px;
  margin-right: 15px;
  padding: 7px;
  padding-bottom: 5px;
  padding-top: 5px;
  width: 30px;
`;

const Image = styled.span`
  border-radius: 50%;
  color: ${WHITE_COLOR};
  display: block;
  font-size: 15px;
  height: 30px;
  margin-right: 15px;
  width: 30px;
  overflow: hidden;
`;

class NotificationsGroup extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    let imgOrIcon;

    if (this.props.imgUrl === "") {
      imgOrIcon = (
        <Icon style={{ backgroundColor: this.props.iconBackground }}>
          <i className={this.props.iconClasses} />
        </Icon>
      );
    } else {
      imgOrIcon = (
        <Image>
          <img src={this.props.imgUrl} alt="default avatar" />
        </Image>
      );
    }

    return (
      <Wrapper className="row">
        <IconWrapper className="col-sm-1">
          {imgOrIcon}
        </IconWrapper>
        <div className="col-sm-10">
          <h5>
            <strong>
              {this.props.title}
            </strong>
          </h5>
          <p>
            {this.props.subtitle}
          </p>
          <NotificationsSwitchGroup type={this.props.type} />
        </div>
      </Wrapper>
    );
  }
}

NotificationsGroup.propTypes = {
  title: PropTypes.string.isRequired,
  subtitle: PropTypes.string.isRequired,
  type: PropTypes.string.isRequired,
  imgUrl: PropTypes.string.isRequired,
  iconClasses: PropTypes.string.isRequired,
  iconBackground: PropTypes.string.isRequired
};

export default NotificationsGroup;
