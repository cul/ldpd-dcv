import { ComponentProps } from "react"
import { Button } from "react-bootstrap"

const SaveButton = (props: ComponentProps<typeof Button>) => {
  return (
    <Button type="submit" className="w-25" disabled={false}  {...props} ><i className="mx-3 far fa-save"></i> Save Changes</Button>
  )
}

export default SaveButton;