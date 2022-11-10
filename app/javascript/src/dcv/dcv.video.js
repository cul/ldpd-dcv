import videojs from "video.js";

const Component = videojs.getComponent('Component');

class Logo extends Component {
  constructor(player, options = {}) {
    super(player, options);
  }
  createEl() {
    const img = videojs.dom.createEl('img', this.options().logo);
    const componentElement = videojs.dom.createEl('div', { className: 'vjs-logo' });
    videojs.appendContent(componentElement, img);
    return componentElement;
  }
};
videojs.registerComponent('Logo', Logo);

const knownVideoJsPlayers = new Map();

window.getVideoJsPlayerForElement = (element) => {
  return knownVideoJsPlayers.get(element);
}

const setVideoJsPlayerForElement = (element, videoJsPlayer) => {
  return knownVideoJsPlayers.set(element, videoJsPlayer);
}

export const videoReady = function () {
  // If synchronizer is present, do nothing. Synchronizer has its own audio/video setup code.
  if ($('#synchronizer-widget').length) { return; }

  const $showPageAudioVideoElements = $('video, audio');
  if ($showPageAudioVideoElements.length > 0) {
    $showPageAudioVideoElements.each(function (_ix, el) {
      el.classList.add('video-js', 'vjs-big-play-centered');

      const options = {
        controls: true,
        responsive: true,
        fluid: true,
        playbackRates: [0.5, 1, 1.5, 2],
        controlBar: {
          remainingTimeDisplay: false
        }
      };

      if (el.nodeName === 'AUDIO') {
        // picture-in-picture doesn't apply to audio, so we won't show the button
        options.controlBar.pictureInPictureToggle = false;
      }

      const player = videojs(el, options);

      if (el.attributes['player-logo']) {
        player.addChild('Logo', { logo: { src: el.attributes['player-logo'].value } });
      }

      setVideoJsPlayerForElement(el, player);
    })
  };
};
