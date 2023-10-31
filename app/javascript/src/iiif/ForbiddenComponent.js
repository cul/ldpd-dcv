import React from 'react';
const ForbiddenComponent = (props) => {
	const { id } = props;
	return (
		<div className="alert alert-warning w-100 d-flex">
		  <h3 className="my-auto mx-auto h6">you do not currently have access to {id}</h3>
		</div>
	);
}

export default ForbiddenComponent;