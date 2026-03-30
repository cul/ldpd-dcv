type ShowHideArrowProps = {
  hidden: boolean;
  clickHandler: ((value: React.SetStateAction<boolean>) => void) | (() => void);
};

const ShowHideArrow = ({ hidden, clickHandler }: ShowHideArrowProps) => {
  return (
    <div style={{cursor: 'pointer'}}
      onClick={() => clickHandler(!hidden)}>
      {hidden ? 
        <i className="fa-duotone fa-solid fa-angle-down"></i> :
        <i className="fa-duotone fa-solid fa-angle-up"></i>
      }
    </div>
  )
}

export default ShowHideArrow;