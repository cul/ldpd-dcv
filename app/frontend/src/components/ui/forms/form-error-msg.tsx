const FormErrorMsg = ({ msg } : {msg: string | undefined }) => {
  if (!msg) return;
  return <p className="text-danger fst-italic">{msg}</p>;
};

export default FormErrorMsg;