type ShowHideArrowProps = {
  hidden: boolean;
  clickHandler: ((value: React.SetStateAction<boolean>) => void) | (() => void);
};

const ShowHideArrow = ({ hidden, clickHandler }: ShowHideArrowProps) => {
  return (
    <div style={{cursor: 'pointer'}}
      onClick={() => clickHandler(!hidden)}
    >
      {hidden 
        ? 
          <i 
            className="fa-solid fa-angle-down" 
            style={{ color: '#000000ad', fontSize: '1.5em'}}
          ></i> 
        :
          <i 
            className="fa-duotone fa-solid fa-angle-up" 
            style={{ fontSize: '1.5em'}}
          ></i>
      }
    </div>
  )
}

export default ShowHideArrow;