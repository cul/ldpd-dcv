import { useNavGroupsSuspense } from "../../api/get-nav-groups";
import { DragDropProvider } from '@dnd-kit/react';
import { isSortable } from '@dnd-kit/dom/sortable';
import { useForm, useFieldArray } from "react-hook-form";
import { Button, Col, Form, Row } from "react-bootstrap";
import z from "zod";
import { zodResolver } from "@hookform/resolvers/zod";

import { NavGroup } from "@/types/api";
import SortableNavGroupFormFields from "./nav-groups-forms/sortable-nav-groups-form-fields";
import { MutationAlerts } from "@/components/ui/forms/mutation-alerts";
import SaveButton from "@/components/ui/forms/save-button";
import { useMUpdateSite } from "../../api/update-site";


const navLinksSchema = z.object({
  linkLabel: z.string().min(1, "Link label is required").max(80, 'the link label must not exceed 80 characters'),
  linkValue: z.string().min(1, "Link value is required").max(500, 'the link value must not exceed 500 characters'),
  external: z.boolean().nullable(),
  iconClass: z.string().max(250, 'the icon class must not exceed 250 characters').nullable(),
});

const navGroupsSchema = z.object({
  groupLabel: z.string().min(1, "Group Label is required").max(80),
  childrenLinks: z.array(navLinksSchema).min(1, "You must provide at least one link to create a navigation group"),
});

const navGroupsFormSchema = z.object({
  navGroups: z.array(navGroupsSchema),
})

type NavGroupFormValues = {
  navGroups: NavGroup[];
}

const NavGroupsForm = ({ slug }: { slug: string }) => {
  // Do not allow background refresh; always overwrite when submitting
  // TODO : handle this interaction better ...
  const navGroups = useNavGroupsSuspense(slug, { queryConfig: { staleTime: Infinity } });
  const mutation = useMUpdateSite();

  const { register, handleSubmit, control, formState: { isDirty, isSubmitting, errors } } = useForm<NavGroupFormValues>({
    defaultValues: {
      navGroups: navGroups,
    },
    mode: 'all',
    resolver: zodResolver(navGroupsFormSchema),
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

  const submitHandler = (data: NavGroupFormValues) => {
    mutation.mutate({
      slug: slug,
      ...data
    })
  }

  return (
    <>
    <p>
      Here you can manage the navigation groups and links for your subsite. Rearrange the display order of Navigation Groups by dragging and dropping the elements to sort horizontally.
      Rearrange the order of the links within a navigation group by dragging and dropping them to sort vertically.
    </p>
    {/* <MutationAlerts /> */}
    <Form onSubmit={handleSubmit(submitHandler)}>
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
              removeNavGroup={remove}
              control={control}
              errors={errors}
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
          <SaveButton disabled={!isDirty || isSubmitting}>
            {isDirty && !isSubmitting && <span className="text-warning fst-italic px-3">(you have unsaved changes)</span>}
          </SaveButton>
        </Row>
      </DragDropProvider>
    </Form>
    </>
  );
}

export {type NavGroupFormValues, NavGroupsForm as default};