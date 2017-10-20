import _ from "lodash";
import {
  NAME_MIN_LENGTH,
  NAME_MAX_LENGTH,
  TEXT_MAX_LENGTH
} from "../../../config/constants/numeric";

export const nameMinLengthValidator = (value, messageIds = {}) => {
  const messageId = _.has(messageIds, "text_too_short") ?
    messageIds.text_too_short :
    "validators.text_validators.text_too_short";


  if (value.length < NAME_MIN_LENGTH) {
    return [{
      intl: true,
      messageId,
      values: { min_length: NAME_MIN_LENGTH }
    }];
  }
  return [];
};

export const nameMaxLengthValidator = (value, messageIds = {}) => {
    const messageId = _.has(messageIds, "text_too_long") ?
    messageIds.text_too_long :
    "validators.text_validators.text_too_long";

  if (value.length > NAME_MAX_LENGTH) {
    return [{
      intl: true,
      messageId,
      values:{ max_length: NAME_MAX_LENGTH }
    }];
  }
  return [];
};

export const nameLengthValidator = (value, messageIds = {}) => {
  const res = nameMinLengthValidator(value, messageIds);
  if (res.length > 0) {
    return res;
  }
  return nameMaxLengthValidator(value, messageIds);
};

export const textMaxLengthValidator = (value, messageIds = {}) => {
  const messageId = _.has(messageIds, "text_too_long") ?
    messageIds.text_too_long :
    "validators.text_validators.text_too_long";

  if (value.length > TEXT_MAX_LENGTH) {
    return [{
      intl: true,
      messageId,
      values: { max_length: TEXT_MAX_LENGTH }
    }];
  }
  return [];
};