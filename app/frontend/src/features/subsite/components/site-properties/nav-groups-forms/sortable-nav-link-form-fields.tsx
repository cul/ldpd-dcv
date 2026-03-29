import { useSortable } from "@dnd-kit/react/sortable";
import { useEffect } from "react";
import { Col, Row, Form, Stack } from "react-bootstrap";
import { UseFieldArrayRemove, UseFormRegister } from "react-hook-form";
import { RestrictToWindow } from '@dnd-kit/dom/modifiers';
import { RestrictToVerticalAxis } from '@dnd-kit/abstract/modifiers';

import { NavGroupFormValues } from "../nav-groups-form";

type SortableNavLinkElementProps = {
  id: string;
  groupIndex: number;
  index: number;
  register: UseFormRegister<NavGroupFormValues>;
  remove: UseFieldArrayRemove;
}

const SortableNavLinkFormFields = ({ id, groupIndex, index, register, remove }: SortableNavLinkElementProps) => {
  const { ref, handleRef } = useSortable({ id: `${id}`, index, modifiers: [RestrictToVerticalAxis, RestrictToWindow]});

  return (
    <div
      ref={ref} 
      key={'group-'+groupIndex+'link-'+index} 
      className="bg-info my-2 py-2">

      <Row className="justify-content-between">
        <Col ref={handleRef} style={{ cursor: 'grab' }}>
          <i className="fa-solid fa-grip"></i>
          <span className="px-2 fst-italic text-secondary">#{index+1}</span>
        </Col> 
        <Col className="d-flex justify-content-end">
          <button
          type="button"
          className="btn btn-danger w-75"
          onClick={() => remove(index)}
        >
          Remove Link
        </button>
        </Col>
      </Row>
      <Stack
        gap={3}
        className="bg-success my-2 py-2">
        <Row>
          <Col xs={4}>
            <Form.Label>Link Label</Form.Label>
          </Col>
          <Col xs={8}>
            <Form.Control {...register(`navGroups.${groupIndex}.childrenLinks.${index}.linkLabel`)} />
          </Col>
        </Row>
        <Row>
          <Col xs={4}>
            <Form.Label>Link Value</Form.Label>
          </Col>
          <Col xs={8}>
            <Form.Control {...register(`navGroups.${groupIndex}.childrenLinks.${index}.linkValue`)} />
          </Col>
        </Row>
        <Row>
          <Col xs={4}>
            <Form.Label>External Link?</Form.Label>
          </Col>
          <Col xs={8} className="">
            <Form.Check {...register(`navGroups.${groupIndex}.childrenLinks.${index}.external`)} />
          </Col>
        </Row>
        <Row>
          <Col xs={4}>
            <Form.Label>Icon Class (optional)</Form.Label>
          </Col>
          <Col xs={8}>
            <Form.Control {...register(`navGroups.${groupIndex}.childrenLinks.${index}.iconClass`)} />
          </Col>
        </Row>
      </Stack>

    </div>
  )
}

export default SortableNavLinkFormFields;