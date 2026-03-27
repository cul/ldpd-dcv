import { useNavGroupsSuspense } from "../../api/get-nav-groups";
import { DragDropProvider } from '@dnd-kit/react';
import { isSortable } from '@dnd-kit/dom/sortable';
import { useSortable } from '@dnd-kit/react/sortable';
import { RestrictToHorizontalAxis } from '@dnd-kit/abstract/modifiers';
import { RestrictToWindow } from '@dnd-kit/dom/modifiers';
import { useForm, useFieldArray, type UseFormRegister, type Control } from "react-hook-form";
import { Button, Col, Form, Row } from "react-bootstrap";
import { NavGroup } from "@/types/api";

type ExampleFormValues = {
  navGroups: NavGroup[];
}

type SortableNavGroupElementProps = {
  id: string;
  index: number;
  register: UseFormRegister<ExampleFormValues>;
  control: Control<ExampleFormValues>;
}

const NavGroupFormFields = ({ id, index, register, control }: SortableNavGroupElementProps) => {
  const { ref, handleRef } = useSortable({ id, index, modifiers: [RestrictToHorizontalAxis, RestrictToWindow] });

  const { fields } = useFieldArray({
    name: `navGroups.${index}.childrenLinks`,
    control
  })

  return (
    <Col xs={4} ref={ref} className="bg-secondary" style={{ margin: 5 }}>
      <Row>
        <Col xs={1} ref={handleRef} style={{ cursor: 'grab' }}>⠿</Col>
        <Col xs={2}>
          <Form.Label>Group Label</Form.Label>
        </Col>
        <Col xs={9}>
          <Form.Control {...register(`navGroups.${index}.groupLabel`)} />
        </Col>
      </Row>
      <Row>
        {fields.map((field, linkIndex) => (
          <div key={'group-'+index+'link-'+linkIndex} className="bg-info my-2">
            <Row>
              <Col>
                <Form.Label>Link Label</Form.Label>
              </Col>
              <Col>
                <Form.Control {...register(`navGroups.${index}.childrenLinks.${linkIndex}.linkLabel`)} />
              </Col>
            </Row>
            <Row>
              <Col>
                <Form.Label>Link Value</Form.Label>
              </Col>
              <Col>
                <Form.Control {...register(`navGroups.${index}.childrenLinks.${linkIndex}.linkValue`)} />
              </Col>
            </Row>
            <Row>
              <Col>
                <Form.Label>External Link?</Form.Label>
              </Col>
              <Col>
                <Form.Check {...register(`navGroups.${index}.childrenLinks.${linkIndex}.external`)} />
              </Col>
            </Row>
            <Row>
              <Col>
                <Form.Label>Icon Class (optional)</Form.Label>
              </Col>
              <Col>
                <Form.Control {...register(`navGroups.${index}.childrenLinks.${linkIndex}.iconClass`)} />
              </Col>
            </Row>
          </div>
        ))}
      </Row>
    </Col>
  );
}

const NavGroupsForm = ({ slug }: { slug: string }) => {
  // Do not allow background refresh; always overwrite when submitting
  // TODO : handle this better
  const navGroups = useNavGroupsSuspense(slug, { queryConfig: { staleTime: Infinity } });

  console.log('initial navGroups data:')
  console.log(navGroups)

  const { register, handleSubmit, control } = useForm<ExampleFormValues>({
    defaultValues: {
      navGroups: navGroups,
    },
  });

  const { fields, move } = useFieldArray({
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
      <DragDropProvider onDragEnd={handleDragEnd}>
        <Row>
          {fields.map((field, index) => (
            <NavGroupFormFields
              key={field.id}
              id={field.id}
              index={index}
              register={register}
              control={control}
            />
          ))}
        </Row>
        <Row>
          <Button className='w-2' type="submit">Submit</Button>
        </Row>
      </DragDropProvider>
    </Form>
  );
}

export default NavGroupsForm;