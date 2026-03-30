import { isSortable, useSortable } from "@dnd-kit/react/sortable";
import { Col, Row, Form } from "react-bootstrap";
import { Control, useFieldArray, UseFormRegister } from "react-hook-form";
import { RestrictToHorizontalAxis } from '@dnd-kit/abstract/modifiers';
import { RestrictToWindow } from '@dnd-kit/dom/modifiers';
import { DragDropProvider } from "@dnd-kit/react";
import { NavGroupFormValues } from "../nav-groups-form";
import { useState } from "react";
import SortableNavLinkFormFields from "./sortable-nav-link-form-fields";
import ShowHideArrow from "@/components/ui/show-hide-arrow";


type SortableNavGroupElementProps = {
  id: string;
  index: number;
  register: UseFormRegister<NavGroupFormValues>;
  control: Control<NavGroupFormValues>;
}


// Helper to move an element in an array from src index to dst index, shifting
// the rest of the elements to the right as needed
// TODO : use splice for this
const moveArrayElements = (original: boolean[], src: number, dst: number) => {
  const copy = [...original];
  const tmp = original[src];
  if (dst < src) {
    for (let i = src; i > dst; i--) {
      copy[i] = original[i-1]
    }
  } else {
    for (let i = src; i < dst; i++) {
      copy[i] = original[i+1]
    }
  }
  copy[dst] = tmp;
  return copy;
}

const SortableNavGroupFormFields = ({ id, index, register, control }: SortableNavGroupElementProps) => {
  const { ref, handleRef } = useSortable({ id, index, modifiers: [RestrictToHorizontalAxis, RestrictToWindow] });

  const { fields, move, append, remove } = useFieldArray({
    name: `navGroups.${index}.childrenLinks`,
    control
  })

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

  // Idea from: https://coreui.io/blog/how-to-force-a-react-component-to-re-render/
  // There was a bug where the child DragDropProviders's state change was not triggering a rerender
  // when the form's state changed with useFieldArray's move().
  // By changing the key whenever a drag occurs in the child DragDropProvider, we force
  // react to rerender it so that the UI state (drag state) matches our form state
  const [ dragProviderKey, setDragProviderKey ] = useState(0);
  const [ hidden, setHidden ] = useState(false);
  const [ hiddenLinksArray, setHiddenLinksArray ] = useState(Array(fields.length).fill(false));
  console.log(`FOR NAV GROUP ${index}, OUR hidden array is:`)
  console.log(hiddenLinksArray);

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
    <Col xs={5} ref={ref} className="rounded p-3 subtle-light-blue-background" style={{ margin: 5 }}>
      <Row>
        <Col xs={1} ref={handleRef} style={{ cursor: 'grab' }}><i className="fa-solid fa-grip-vertical"></i></Col>
        <Col xs={2}>
          <Form.Label>Group Label</Form.Label>
        </Col>
        <Col xs={8}>
          <Form.Control {...register(`navGroups.${index}.groupLabel`)} />
        </Col>
        <Col xs={1}>
          <ShowHideArrow hidden={hidden} clickHandler={setHidden} />
        </Col>
      </Row>

        <Row className="overflow-auto" style={{ maxHeight: '50vh', display: hidden ? 'none' : undefined  }} >
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
                remove={() => removeLink(linkIndex)} />
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