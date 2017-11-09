// @flow

import _ from "lodash";
import type { ValidationError } from "flow-typed";
import {
  NAME_MIN_LENGTH,
  NAME_MAX_LENGTH,
  TEXT_MAX_LENGTH,
  PASSWORD_MIN_LENGTH,
  PASSWORD_MAX_LENGTH,
  USER_INITIALS_MAX_LENGTH
} from "../../../config/constants/numeric";
import { EMAIL_REGEX } from "../../../config/constants/strings";

export const nameMinLengthValidator = (
  target: HTMLInputElement,
  messageIds: { [string]: string } = {}): Array<ValidationError> => {
  const messageId = _.has(messageIds, "text_too_short") ?
    messageIds.text_too_short :
    "validators.text.text_too_short";
  const value = target.value;

  if (value.length < NAME_MIN_LENGTH) {
    return [{
      intl: true,
      messageId,
      values: { min_length: NAME_MIN_LENGTH }
    }];
  }
  return [];
};

export const nameMaxLengthValidator = (
  target: HTMLInputElement,
  messageIds: { [string]: string } = {}): Array<ValidationError> => {
  const messageId = _.has(messageIds, "text_too_long") ?
  messageIds.text_too_long :
  "validators.text.text_too_long";
  const value = target.value;

  if (value.length > NAME_MAX_LENGTH) {
    return [{
      intl: true,
      messageId,
      values:{ max_length: NAME_MAX_LENGTH }
    }];
  }
  return [];
};

export const nameLengthValidator = (
  target: HTMLInputElement,
  messageIds: { [string]: string } = {}): Array<ValidationError> => {
  const res = nameMinLengthValidator(target, messageIds);
  if (res.length > 0) {
    return res;
  }
  return nameMaxLengthValidator(target, messageIds);
};

export const textBlankValidator = (
  target: HTMLInputElement,
  messageIds: { [string]: string } = {}): Array<ValidationError> => {
  const messageId = _.has(messageIds, "text_blank") ?
    messageIds.text_blank :
    "validators.text.text_blank";
  const value = target.value;

    if (value.length === 0) {
    return [{
      intl: true,
      messageId
    }];
  }
  return [];
}

export const textMaxLengthValidator = (
  target: HTMLInputElement,
  messageIds: { [string]: string } = {}): Array<ValidationError> => {
  const messageId = _.has(messageIds, "text_too_long") ?
    messageIds.text_too_long :
    "validators.text.text_too_long";
  const value = target.value;

  if (value.length > TEXT_MAX_LENGTH) {
    return [{
      intl: true,
      messageId,
      values: { max_length: TEXT_MAX_LENGTH }
    }];
  }
  return [];
};

export const passwordLengthValidator = (
  target: HTMLInputElement,
  messageIds: { [string]: string } = {}): Array<ValidationError> => {
  const messageIdTooShort = _.has(messageIds, "text_too_short") ?
    messageIds.text_too_short :
    "validators.text.text_too_short";
  const messageIdTooLong = _.has(messageIds, "text_too_long") ?
    messageIds.text_too_long :
    "validators.text.text_too_long";
  const value = target.value;

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

export const userInitialsMaxLengthValidator = (
  target: HTMLInputElement,
  messageIds: { [string]: string } = {}): Array<ValidationError> => {
  const messageId = _.has(messageIds, "text_too_long") ?
    messageIds.text_too_long :
    "validators.text.text_too_long";
  const value = target.value;

  if (value.length > USER_INITIALS_MAX_LENGTH) {
    return [{
      intl: true,
      messageId,
      values: { max_length: USER_INITIALS_MAX_LENGTH }
    }];
  }
  return [];
};

export const emailValidator = (
  target: HTMLInputElement,
  messageIds: { [string]: string } = {}): Array<ValidationError> => {
  const res = textBlankValidator(target, messageIds);
  if (res.length > 0) {
    return res;
  }

  const messageId = _.has(messageIds, "invalid_email") ?
    messageIds.invalid_email :
    "validators.text.invalid_email";
  const value = target.value;

  if (!EMAIL_REGEX.test(value)) {
    return [{ intl: true, messageId }];
  }
  return [];
};