// @flow

import _ from "lodash";
import type { ValidationError } from "flow-typed";
import { AVATAR_MAX_SIZE_MB } from "../../../config/constants/numeric";
import { AVATAR_VALID_EXTENSIONS } from "../../../config/constants/strings";

export const avatarExtensionValidator = (
  target: HTMLInputElement,
  messageIds: { [string]: string } = {}): Array<ValidationError> => {
  const messageId = _.has(messageIds, "invalid_file_extension") ?
    messageIds.invalid_file_extension :
    "validators.file.invalid_file_extension";

  const filePath = target.value;
  const ext = filePath
              .substring(filePath.lastIndexOf(".") + 1)
              .toLowerCase();
  const validExtsString = AVATAR_VALID_EXTENSIONS
                          .map(val => `.${val}`)
                          .join(", ");

  if (!_.includes(AVATAR_VALID_EXTENSIONS, ext)) {
    return [{
      intl: true,
      messageId,
      values: { valid_extensions: validExtsString }
    }];
  }
  return [];
}

export const avatarSizeValidator = (
  target: HTMLInputElement,
  messageIds: { [string]: string } = {}): Array<ValidationError> => {
  const messageId = _.has(messageIds, "file_too_large") ?
    messageIds.file_too_large :
    "validators.file.file_too_large";
  const maxSizeKb = AVATAR_MAX_SIZE_MB * 1024;

  if (target.files && target.files[0]) {
    const fileSize = target.files[0].size / 1024; // size in KB
    if (fileSize > maxSizeKb) {
      return [{
      intl: true,
      messageId,
      values: { max_size: AVATAR_MAX_SIZE_MB }
    }];
    }
  }
  return [];
}