import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { styled } from '@mui/material/styles';
import Typography from '@mui/material/Typography';
import Link from '@mui/material/Link';
import classNames from 'classnames';
import CollapsibleSection from '@columbia-libraries/mirador/dist/es/src/containers/CollapsibleSection';
import ns from '@columbia-libraries/mirador/dist/es/src/config/css-ns';

const StyledDl = styled('dl')(({ theme }) => ({
  '& dd': {
    marginBottom: '.5em',
    marginLeft: '0',
  },
}));

const hasContent = (arr) => arr && arr.length > 0;

/**
 * CanvasRelatedLinks
 */
export class CanvasRelatedLinks extends Component {
  /**
   * render
   * @return
   */
  render() {
    const {
      related,
      renderings,
      seeAlso,
      id,
      t,
    } = this.props;

    if (!hasContent(related) && !hasContent(renderings) && !hasContent(seeAlso)) return (<div></div>); 

    return (
      <>
        <Typography
          aria-labelledby={`${id}-related ${id}-related-heading`}
          id={`${id}-related-heading`}
          variant="h6"
          component="h5"
        >
          {t('links')}
        </Typography>
        <StyledDl className={classNames(ns('label-value-metadata'))}>
          { renderings && renderings.length > 0 && (
            <>
              <Typography variant="subtitle3" component="dt">{t('iiif_renderings')}</Typography>
              {
                renderings.map(rendering => (
                  <Typography key={rendering.value} variant="body1" component="dd">
                    <Link target="_blank" rel="noopener noreferrer" href={rendering.value}>
                      {rendering.label || rendering.value}
                    </Link>
                  </Typography>
                ))
              }
            </>
          )}
          { related && (
            <>
              <Typography variant="subtitle3" component="dt">{t('iiif_related')}</Typography>
              {
                related.map(relatedItem => (
                  <Typography key={relatedItem.value} variant="body1" component="dd">
                    <Link target="_blank" rel="noopener noreferrer" href={relatedItem.value}>
                      {relatedItem.label || relatedItem.value}
                    </Link>
                    { relatedItem.format && (
                      <Typography component="span">{` (${relatedItem.format})`}</Typography>
                    )}
                  </Typography>
                ))
              }
            </>
          )}
          { seeAlso && (
            <>
              <Typography variant="subtitle3" component="dt">{t('iiif_seeAlso')}</Typography>
              {
                seeAlso.map(seeAlsoItem => (
                  <Typography key={seeAlsoItem.value} variant="body1" component="dd">
                    <Link target="_blank" rel="noopener noreferrer" href={seeAlsoItem.value}>
                      {seeAlsoItem.label || seeAlsoItem.value}
                    </Link>
                    { seeAlsoItem.format && (
                      <Typography component="span">{` (${seeAlsoItem.format})`}</Typography>
                    )}
                  </Typography>
                ))
              }
            </>
          )}
        </StyledDl>
      </>
    );
  }
}

CanvasRelatedLinks.propTypes = {
  id: PropTypes.string.isRequired,
  related: PropTypes.arrayOf(PropTypes.shape({
    format: PropTypes.string,
    label: PropTypes.string,
    value: PropTypes.string,
  })),
  renderings: PropTypes.arrayOf(PropTypes.shape({
    label: PropTypes.string,
    value: PropTypes.string,
  })),
  seeAlso: PropTypes.arrayOf(PropTypes.shape({
    format: PropTypes.string,
    label: PropTypes.string,
    value: PropTypes.string,
  })),
  t: PropTypes.func,
};

CanvasRelatedLinks.defaultProps = {
  related: null,
  renderings: null,
  seeAlso: null,
  t: key => key,
};
