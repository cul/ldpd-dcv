import { useNavGroupsSuspense } from "../../api/get-nav-groups";
import { DragDropProvider } from '@dnd-kit/react';
import { isSortable } from '@dnd-kit/dom/sortable';
import { useForm, useFieldArray } from "react-hook-form";
import { Button, Col, Form, Row } from "react-bootstrap";

import { NavGroup } from "@/types/api";
import SortableNavGroupFormFields from "./nav-groups-forms/sortable-nav-groups-form-fields";
import { MutationAlerts } from "@/components/ui/forms/mutation-alerts";
import SaveButton from "@/components/ui/forms/save-button";


type NavGroupFormValues = {
  navGroups: NavGroup[];
}

const NavGroupsForm = ({ slug }: { slug: string }) => {
  // Do not allow background refresh; always overwrite when submitting
  // TODO : handle this better ...
  const navGroups = useNavGroupsSuspense(slug, { queryConfig: { staleTime: Infinity } });

  console.log('initial navGroups data:')
  console.log(navGroups)

  const { register, handleSubmit, control, formState: { isDirty, isSubmitting } } = useForm<NavGroupFormValues>({
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
    <>
    <p>
      Here you can manage the navigation groups and links for your subsite. Rearrange the display order of Navigation Groups by dragging and dropping the elements to sort horizontally.
      Rearrange the order of the links within a navigation group by dragging and dropping them to sort vertically.
    </p>
    {/* <MutationAlerts /> */}
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
          
          {/* <SaveButton disabled={!isDirty || isSubmitting}>
            {isDirty && !isSubmitting && <span className="text-warning fst-italic px-3">(you have unsaved changes)</span>}
          </SaveButton> */}
          <Button className='w-25' type="submit">Submit</Button>
        </Row>
      </DragDropProvider>
    </Form>
    </>
  );
}

export {type NavGroupFormValues, NavGroupsForm as default};