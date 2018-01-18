// @flow
import React from "react";
import type { Node } from "react";
import { FormattedMessage } from "react-intl";
import { Modal } from "react-bootstrap";

type Props = {
  showModal: boolean,
  scinoteVersion: string,
  addons: Array<string>,
  onModalClose: Function
};

export default (props: Props): Node => {
  const { showModal, scinoteVersion, addons, onModalClose } = props;
  return (
    <Modal show={showModal} onHide={onModalClose}>
      <Modal.Header closeButton>
        <Modal.Title>
          <FormattedMessage id="general.about_scinote" />
        </Modal.Title>
      </Modal.Header>
      <Modal.Body>
        <strong>
          <FormattedMessage id="general.core_version" />
        </strong>
        <p>{scinoteVersion}</p>
        {addons.length > 0 &&
          <span>
            <strong>
              <FormattedMessage id="general.addon_versions" />
            </strong>
            {
              addons.map(
                (addon: string): Node => (<p key={addon}>{addon}</p>)
              )
            }
          </span>
        }
      </Modal.Body>
    </Modal>
  );
};
