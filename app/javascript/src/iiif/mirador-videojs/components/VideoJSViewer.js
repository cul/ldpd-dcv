import React, { Component } from 'react';
import { connect } from 'react-redux';
import { compose } from 'redux';
import { withTranslation } from 'react-i18next';
import { VideoViewer } from '@columbia-libraries/mirador/dist/es/src/components/VideoViewer';
import { getConfig, getVisibleCanvasCaptions, getVisibleCanvasVideoResources } from '@columbia-libraries/mirador/dist/es/src/state/selectors';

import VideoJS from './VideoJS';
import ForbiddenComponent from "../../ForbiddenComponent";

/** */
const mapStateToProps = (state, { windowId }) => (
  {
    captions: getVisibleCanvasCaptions(state, { windowId }) || [],
    videoOptions: getConfig(state).videoOptions,
    videoResources: getVisibleCanvasVideoResources(state, { windowId }) || [],
  }
);

const enhance = compose(
  withTranslation(),
  connect(mapStateToProps, null),
);

class VideoJSViewerBase extends VideoViewer {
  render() {
    const {
      captions, videoOptions, videoResources,
    } = this.props;

    const videoJsOptions = {
      playbackRates: [0.5, 1, 1.5, 2],
      controlBar: {
        remainingTimeDisplay: false
      },
      autoplay: false,
      controls: true,
      responsive: true,
      fluid: true,
      sources: videoResources.filter(video => video.id && video.getFormat()).map(video => ({ src: video.id, type: video.getFormat() })),
      tracks: captions.filter(caption => caption.id).map(caption => ({ kind: (caption.kind || 'captions'), src: caption.id })),
    };

    console.log({videoJsOptions, state: this.state});
    if (videoJsOptions.sources.length == 0) return <ForbiddenComponent id="this content"></ForbiddenComponent>;
    return (
      <div className="video-js w-100" data-vjs-player>
        <VideoJS options={videoJsOptions} />
      </div>
    );
  }
}

export const VideoJSViewer = enhance(VideoJSViewerBase);

/** */
export default function ({ _targetComponent, targetProps  }) {
  return <VideoJSViewer {...targetProps}></VideoJSViewer>;
}
