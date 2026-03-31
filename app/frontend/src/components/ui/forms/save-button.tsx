import { ComponentProps } from "react"
import { Button } from "react-bootstrap"

import { formatDateRelative } from "@/lib/utils";


type SaveButtonProps = ComponentProps<typeof Button> & {
  isDirty?: boolean;
  isSubmitting?: boolean;
  updatedAt?: string;
}

// A Bootstrap React button that optionally displays the last updated and dirty status of a form
const SaveButton = ({ isDirty, updatedAt, isSubmitting, ...props }: SaveButtonProps) => {
  return (
    <div className={isDirty ? 'text-warning fst-italic' : 'text-muted'}>
      <Button disabled={isDirty !== undefined ? !isDirty || isSubmitting : isSubmitting} type="submit" className="w-25" {...props} ><i className="mx-3 far fa-save"></i> Save Changes</Button>
      {updatedAt && <span className={`px-3`}>Last updated: {formatDateRelative(updatedAt)} {isDirty && '(unsaved changes)'}</span>}
      {props.children}
    </div>
  )
}

export default SaveButton;