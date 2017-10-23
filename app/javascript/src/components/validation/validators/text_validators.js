import _ from "lodash";
import {
  NAME_MIN_LENGTH,
  NAME_MAX_LENGTH,
  TEXT_MAX_LENGTH,
  PASSWORD_MIN_LENGTH,
  PASSWORD_MAX_LENGTH,
  USER_INITIALS_MAX_LENGTH
} from "../../../config/constants/numeric";
import { EMAIL_REGEX } from "../../../config/constants/strings";

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

export const textBlankValidator = (value, messageIds = {}) => {
  const messageId = _.has(messageIds, "text_blank") ?
    messageIds.text_blank :
    "validators.text_validators.text_blank";

    if (value.length === 0) {
    return [{
      intl: true,
      messageId
    }];
  }
  return [];
}

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

export const passwordLengthValidator = (value, messageIds = {}) => {
  const messageIdTooShort = _.has(messageIds, "text_too_short") ?
    messageIds.text_too_short :
    "validators.text_validators.text_too_short";
  const messageIdTooLong = _.has(messageIds, "text_too_long") ?
    messageIds.text_too_long :
    "validators.text_validators.text_too_long";

  if (value.length < PASSWORD_MIN_LENGTH) {
    return [{
      intl: true,
      messageId: messageIdTooShort,
      values:{ min_length: PASSWORD_MIN_LENGTH }
    }];
  } else if (value.length > PASSWORD_MAX_LENGTH) {
    return [{
      intl: true,
      messageId: messageIdTooLong,
      values:{ max_length: PASSWORD_MAX_LENGTH }
    }];
  }
  return [];
};

export const userInitialsMaxLengthValidator = (value, messageIds = {}) => {
  const messageId = _.has(messageIds, "text_too_long") ?
    messageIds.text_too_long :
    "validators.text_validators.text_too_long";

  if (value.length > USER_INITIALS_MAX_LENGTH) {
    return [{
      intl: true,
      messageId,
      values: { max_length: USER_INITIALS_MAX_LENGTH }
    }];
  }
  return [];
};

export const emailValidator = (value, messageIds = {}) => {
  const res = textBlankValidator(value, messageIds);
  if (res.length > 0) {
    return res;
  }

  const messageId = _.has(messageIds, "invalid_email") ?
    messageIds.invalid_email :
    "validators.text_validators.invalid_email";

  if (!EMAIL_REGEX.test(value)) {
    return [{ intl: true, messageId }];
  }
  return [];
};