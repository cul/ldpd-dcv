import { isSortable, useSortable } from "@dnd-kit/react/sortable";
import { Col, Row, Form } from "react-bootstrap";
import { Control, useFieldArray, UseFormRegister } from "react-hook-form";
import { RestrictToHorizontalAxis } from '@dnd-kit/abstract/modifiers';
import { RestrictToWindow } from '@dnd-kit/dom/modifiers';
import { DragDropProvider } from "@dnd-kit/react";
import { NavGroupFormValues } from "../nav-groups-form";
import { useState } from "react";
import SortableNavLinkFormFields from "./sortable-nav-link-form-fields";


type SortableNavGroupElementProps = {
  id: string;
  index: number;
  register: UseFormRegister<NavGroupFormValues>;
  control: Control<NavGroupFormValues>;
}

const SortableNavGroupFormFields = ({ id, index, register, control }: SortableNavGroupElementProps) => {
  const { ref, handleRef } = useSortable({ id, index, modifiers: [RestrictToHorizontalAxis, RestrictToWindow] });
  // Idea from: https://coreui.io/blog/how-to-force-a-react-component-to-re-render/
  // There was a bug where the child DragDropProviders's state change was not triggering a rerender
  // when the form's state changed with useFieldArray's move().
  // By changing the key whenever a drag occurs in the child DragDropProvider, we force
  // react to rerender it so that the UI state (drag state) matches our form state
  const [ dragProviderKey, setDragProviderKey ] = useState(0);

  const { fields, move, append, remove } = useFieldArray({
    name: `navGroups.${index}.childrenLinks`,
    control
  })


  const handleDragEnd: React.ComponentProps<typeof DragDropProvider>['onDragEnd'] = (event) => {
    // https://github.com/clauderic/dnd-kit/issues/1564
    if (event.canceled) return;
    const { source } = event.operation;
    if (!source || !isSortable(source)) return;

    const oldIndex = source.sortable.initialIndex;
    const newIndex = source.sortable.index;
    if (oldIndex !== newIndex) {
      move(oldIndex, newIndex);
      setDragProviderKey(dragProviderKey + 1);
    }
  };

  return (
    <Col xs={4} ref={ref} className="rounded p-3 subtle-light-background" style={{ margin: 5 }}>
      <Row>
        <Col xs={1} ref={handleRef} style={{ cursor: 'grab' }}><i className="fa-solid fa-grip-vertical"></i></Col>
        <Col xs={2}>
          <Form.Label>Group Label</Form.Label>
        </Col>
        <Col xs={9}>
          <Form.Control {...register(`navGroups.${index}.groupLabel`)} />
        </Col>
      </Row>
      <Row className="overflow-auto" style={{ maxHeight: '50vh' }}>
        <DragDropProvider
          key={dragProviderKey}
          onDragEnd={handleDragEnd}
        >
          {fields.map((field, linkIndex) => (
            <SortableNavLinkFormFields 
              key={field.id} 
              groupIndex={index} 
              id={field.id} 
              index={linkIndex} 
              register={register}
              remove={remove} />
          ))}
          <button 
            type="button" 
            className="btn btn-success" 
            onClick={() => append({
              linkLabel: '',
              linkValue: '',
              external: false,
              iconClass: ''
            })}>Add a link</button>
        </DragDropProvider>
      </Row>
    </Col>
  );
}

export default SortableNavGroupFormFields;