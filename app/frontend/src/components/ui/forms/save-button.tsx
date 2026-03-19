import { ComponentProps } from "react"
import { Button } from "react-bootstrap"

import { formatDateRelative } from "@/lib/utils";


type SaveButtonProps = ComponentProps<typeof Button> & {
  isDirty?: boolean;
  updatedAt?: string;
}

// A Bootstrap React button that optionally displays the last updated and dirty status of a form
const SaveButton = ({ isDirty, updatedAt, ...props }: SaveButtonProps) => {
  return (
    <div>
      <Button type="submit" className="w-25" {...props} ><i className="mx-3 far fa-save"></i> Save Changes</Button>
      {updatedAt && <span className={`px-3 ${isDirty ? 'text-warning fst-italic' : 'text-muted'}`}>Last updated: {formatDateRelative(updatedAt)} {isDirty && '(unsaved changes)'}</span>}
      {!updatedAt && isDirty && <span className="px-3 text-warning fst-italic">(unsaved changes)</span>}
      {props.children}
    </div>
  )
}

export default SaveButton;