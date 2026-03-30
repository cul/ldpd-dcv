import { useSortable } from "@dnd-kit/react/sortable";
import { Col, Row, Form, Stack, Button } from "react-bootstrap";
import { UseFieldArrayRemove, UseFormRegister } from "react-hook-form";
import { RestrictToWindow } from '@dnd-kit/dom/modifiers';
import { RestrictToVerticalAxis } from '@dnd-kit/abstract/modifiers';

import { NavGroupFormValues } from "../nav-groups-form";
import ShowHideArrow from "@/components/ui/show-hide-arrow";


type SortableNavLinkElementProps = {
  id: string;
  groupIndex: number;
  index: number;
  register: UseFormRegister<NavGroupFormValues>;
  remove: UseFieldArrayRemove;
  hidden: boolean;
  setHiddenLinksArray: React.Dispatch<React.SetStateAction<boolean[]>>;
}

const SortableNavLinkFormFields = ({ id, groupIndex, index, register, remove, hidden, setHiddenLinksArray }: SortableNavLinkElementProps) => {
  const { ref, handleRef } = useSortable({ id: `${id}`, index, modifiers: [RestrictToVerticalAxis, RestrictToWindow]});

  const changeHidden = () => {
    setHiddenLinksArray((prev) => {
      const newArray = [...prev];
      newArray[index] = !hidden;
      return newArray;
    })
  }

  return (
    <div
      ref={ref} 
      key={'group-'+groupIndex+'link-'+index} 
      className="subtle-light-grey-background rounded my-2 py-2">

      <Row className="justify-content-between align-items-center mb-4">
        <Col xs={1}>
          <div ref={handleRef} className="d-flex flex-column align-items-start" style={{ cursor: 'grab', width: 'fit-content' }}>
            <i className="fa-solid fa-grip"></i>
            <span className="fst-italic text-secondary">#{index+1}</span>
          </div>
        </Col> 
        <Col xs={2}>
          <Form.Label>Link Label</Form.Label>
        </Col>
        <Col xs={8}>
          <Form.Control {...register(`navGroups.${groupIndex}.childrenLinks.${index}.linkLabel`)} />
        </Col>
        <Col xs={1} className="d-flex justify-content-end">
         
         <ShowHideArrow hidden={hidden} clickHandler={changeHidden} />
        {/* <div style={{cursor: 'pointer'}}
          onClick={changeHidden}>
          {hidden ? 
            <i className="fa-duotone fa-solid fa-angle-down"></i> :
            <i className="fa-duotone fa-solid fa-angle-up"></i>
          }
        </div> */}
        </Col>
      </Row>

      { !hidden && (
        <Stack
          gap={3}
          className=" my-2 py-2">
          <Row className=" ps-3">
            <Button
              variant="danger"
              style={{fontSize: '0.85em', width: 'fit-content'}}
              onClick={() => remove(index)}
            >
              Remove Link
            </Button>
          </Row>
          <Row>
          
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
      )}

    </div>
  )
}

export default SortableNavLinkFormFields;