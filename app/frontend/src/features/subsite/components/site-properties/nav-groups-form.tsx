import { useNavGroupsSuspense } from "../../api/get-nav-groups";
import { DragDropProvider } from '@dnd-kit/react';
import { isSortable } from '@dnd-kit/dom/sortable';
import { useSortable } from '@dnd-kit/react/sortable';
import { useForm, useFieldArray, type UseFormRegister, type Control } from "react-hook-form";
import { Button, Col, Form, Row } from "react-bootstrap";

import { NavGroup } from "@/types/api";
import SortableNavGroupFormFields from "./nav-groups-forms/sortable-nav-groups-form-fields";
import { AutoScroller } from "@dnd-kit/dom";


type NavGroupFormValues = {
  navGroups: NavGroup[];
}

const NavGroupsForm = ({ slug }: { slug: string }) => {
  // Do not allow background refresh; always overwrite when submitting
  // TODO : handle this better ...
  const navGroups = useNavGroupsSuspense(slug, { queryConfig: { staleTime: Infinity } });

  console.log('initial navGroups data:')
  console.log(navGroups)

  const { register, handleSubmit, control } = useForm<NavGroupFormValues>({
    defaultValues: {
      navGroups: navGroups,
    },
  });

  const { fields, move, append, remove } = useFieldArray({
    name: 'navGroups',
    control,
  });

  const handleDragEnd: React.ComponentProps<typeof DragDropProvider>['onDragEnd'] = (event) => {
    // https://github.com/clauderic/dnd-kit/issues/1564
    if (event.canceled) return;
    const { source } = event.operation;
    if (!source || !isSortable(source)) return;

    const oldIndex = source.sortable.initialIndex;
    const newIndex = source.sortable.index;
    if (oldIndex !== newIndex) {
      move(oldIndex, newIndex);
    }
  };

  return (
    <Form onSubmit={handleSubmit((data)=>console.log(data))}>
      <DragDropProvider 
        onDragEnd={handleDragEnd}
      >
        <Row className="flex-nowrap overflow-auto">
          {fields.map((field, index) => (
            <SortableNavGroupFormFields
              key={field.id}
              id={field.id}
              index={index}
              register={register}
              control={control}
            />
          ))}
          <Col xs='1'>
            <button 
              type="button" 
              className="btn btn-success h-100"
              onClick={() => append({
                groupLabel: '',
                childrenLinks: [],
              })}>
                +
            </button>
          </Col>
        </Row>
        <Row>
          <Button className='w-25' type="submit">Submit</Button>
        </Row>
      </DragDropProvider>
    </Form>
  );
}

export {type NavGroupFormValues, NavGroupsForm as default};