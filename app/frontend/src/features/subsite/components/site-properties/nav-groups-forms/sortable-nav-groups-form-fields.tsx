import { useState } from "react";
import { isSortable, useSortable } from "@dnd-kit/react/sortable";
import { Col, Row, Form, Button } from "react-bootstrap";
import { Control, FieldErrors, useFieldArray, UseFieldArrayRemove, UseFormRegister } from "react-hook-form";
import { RestrictToHorizontalAxis } from '@dnd-kit/abstract/modifiers';
import { RestrictToWindow } from '@dnd-kit/dom/modifiers';
import { DragDropProvider } from "@dnd-kit/react";

import { NavGroupFormValues } from "../nav-groups-form";
import SortableNavLinkFormFields from "./sortable-nav-link-form-fields";
import ShowHideArrow from "@/components/ui/show-hide-arrow";
import { moveArrayElements, sitePropertiesTooltipMessage } from "@/features/subsite/utils";
import InfoTooltip from "@/components/ui/forms/info-tooltip";


type SortableNavGroupElementProps = {
  id: string;
  index: number;
  register: UseFormRegister<NavGroupFormValues>;
  removeNavGroup: UseFieldArrayRemove;
  control: Control<NavGroupFormValues>;
  errors: FieldErrors<NavGroupFormValues>;
}

const SortableNavGroupFormFields = (
  { id, index, register, removeNavGroup, control, errors }: SortableNavGroupElementProps) => {
  const { ref, handleRef } = useSortable({ id, index, modifiers: [RestrictToHorizontalAxis, RestrictToWindow] });

  const { fields, move, append, remove } = useFieldArray({
    name: `navGroups.${index}.childrenLinks`,
    control
  })

  // Idea from: https://coreui.io/blog/how-to-force-a-react-component-to-re-render/
  // There was a bug where the child DragDropProviders's state change was not triggering a rerender
  // when the form's state changed with useFieldArray's move().
  // By changing the key whenever a drag occurs in the child DragDropProvider, we force
  // react to rerender it so that the UI state (drag state) matches our form state
  const [ dragProviderKey, setDragProviderKey ] = useState(0);
  const [ isHidden, setIsHidden ] = useState(true);
  const [ hiddenLinksArray, setHiddenLinksArray ] = useState(Array(fields.length).fill(true));

  // When we append a new link, we also need to update our hiddenLink state array
  const appendNewLink = () => {
    append({
      linkLabel: '',
      linkValue: '',
      external: false,
      iconClass: ''
    });
    setHiddenLinksArray((prev) => [...prev, false]);
  }

  // When we remove a new link, we also need to remove its corresponding element
  // in the hiddenLink state array
  const removeLink = (linkIndex: number) => {
    remove(linkIndex);
    setHiddenLinksArray((prev) => {
      const newArray = [...prev];
      newArray.splice(linkIndex, 1);
      return newArray;
    });
  }

  const handleDragEnd: React.ComponentProps<typeof DragDropProvider>['onDragEnd'] = (event) => {
    // https://github.com/clauderic/dnd-kit/issues/1564
    if (event.canceled) return;
    const { source } = event.operation;
    if (!source || !isSortable(source)) return;

    const oldIndex = source.sortable.initialIndex;
    const newIndex = source.sortable.index;
    if (oldIndex !== newIndex) {
      move(oldIndex, newIndex);
      // swap order of hidden elements as well
      setHiddenLinksArray(moveArrayElements(hiddenLinksArray, oldIndex, newIndex));
      setDragProviderKey(dragProviderKey + 1);
    }
  };

  return (
    <Col xs={4} ref={ref} className="rounded p-3 subtle-light-blue-background" style={{ margin: 5, maxWidth: 400}}>
      <div>
        <div className="d-flex justify-content-between mb-2">
          <div ref={handleRef} style={{ cursor: 'grab' }}>
            <i className="fa-solid fa-grip-vertical"></i>
            <span className="ps-2 fst-italic text-secondary">#{index+1}</span>
          </div>
          <ShowHideArrow hidden={isHidden} clickHandler={setIsHidden} />
        </div>
        <Row>
          <div className="d-flex align-items-center gap-1 mb-1">
            <InfoTooltip fieldName='groupLabel' lookupFn={sitePropertiesTooltipMessage}  />
            <Form.Label className="mb-0">Group Label:</Form.Label>
          </div>
          <Col xs={8}>
            <Form.Control {...register(`navGroups.${index}.groupLabel`, {
              setValueAs: (value: string) => value.trim(),
            })} placeholder="Group Label" />
            {errors && errors.navGroups?.[index]?.groupLabel && <p><Form.Text className="text-danger">{errors.navGroups[index].groupLabel?.message}</Form.Text></p>}
            {errors && errors.navGroups?.[index]?.childrenLinks && <p><Form.Text className="text-danger">{errors.navGroups[index].childrenLinks?.message}</Form.Text></p>}
          </Col>
        </Row>
        { !isHidden && <>
          <Row>
            <Button 
              className="mx-auto mt-3 mb-1"
              variant='danger' 
              style={{ fontSize: '.85em', width: 'fit-content'}}
              onClick={() => removeNavGroup(index)}
              >
              Remove Nav Group
            </Button>
          </Row>
          <hr className="my-2 mx-auto w-75 text-primary"/>
        </>}
      </div>
        <Row className="overflow-auto" style={{ maxHeight: '75vh', display: isHidden ? 'none' : undefined  }} >
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
                hidden={hiddenLinksArray[linkIndex]}
                setHiddenLinksArray={setHiddenLinksArray}
                register={register}
                remove={() => removeLink(linkIndex)}
                errors={errors}
              />  
            ))}
            <button 
              type="button" 
              className="btn btn-success" 
              onClick={appendNewLink}>
                Add a link
            </button>
          </DragDropProvider>
        </Row>
    </Col>
  );
}

export default SortableNavGroupFormFields;