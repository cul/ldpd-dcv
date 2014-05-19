(function($) {
  $.DjTileUrlBehavior = {

    /**
     * @function
     * @name OpenSeadragon.DjTileSource.prototype.getTileUrl
     * @param {Number}
     *            level
     * @param {Number}
     *            x
     * @param {Number}
     *            y
     */
    getTileUrl : function(level, x, y) {
      var newScale = Math.pow(2, this.maxLevel) / Math.pow(2, level);
      var tileSize = parseInt(newScale * 256, 10);
      var tileSizeX, tileSizeY, region;
      var scale = Math.pow(2, level);

      if (level > 8) {
        var myX = parseInt(x, 10);
        var myY = parseInt(y, 10);

        if (myX === 0) {
          tileSizeX = tileSize - 1;
        } else {
          tileSizeX = tileSize;
        }

        if (myY === 0) {
          tileSizeY = tileSize - 1;
        } else {
          tileSizeY = tileSize;
        }

        var startX = parseInt(myX * tileSize, 10);
        var startY = parseInt(myY * tileSize, 10);

        region = startY + "," + startX + "," + tileSizeY + "," + tileSizeX;
      } else {
        region = "full";
      }

      return this.baseURL + this.imageID + "/" + region + "/" + scale;
    }
  };
  /**
   * An OpenSeadragon interface for the freelib-djatoka JP2 server. It is
   * based on Doug Reside's DjatokaSeadragon, but modified to work with the
   * newer fork of OpenSeadragon that's being developed by Chris Thatcher at
   * LoC.
   *
   * https://github.com/dougreside/DjatokaSeadragon
   * https://github.com/thatcher/openseadragon
   *
   * @class
   * @extends OpenSeadragon.TileSource
   * @param {string}
   *            djatoka
   * @param {string}
   *            imageID
   */
  $.DjTileSource = function(djatoka, imageID) {
    var xml, wItems, wNode, hItems, hNode, w, h;
    var tileOverlap = 0;
    var tileSize = 256;
    var minLev, maxLev; // handled in TileSource
    var http, text;

    this.baseURL = djatoka + "zoom/";
    this.imageID = imageID;

    // If we're using a IE < 10, use XDomainRequest, else XMLHttpRequest
    if (typeof XDomainRequest != 'undefined' && !window.atob) {
      http = new XDomainRequest();
      http.open('GET', djatoka + "image/" + imageID + "/info.xml");
      /* Spent too much time trying to get http.onload to work for IE */
    } else {
      http = new XMLHttpRequest();
      http.open('GET', djatoka + "image/" + imageID + "/info.xml", false);
    }

    try {
      http.send();
      text = http.responseText;

      /* Hacky workaround to get IE's async XDomainRequest to work */
      /* It's deprecated anyway; I want to implement the IIIF interface */
      if (text === '') {
        alert('Older versions of Internet Explorer are only partially supported.\nPlease consider upgrading your browser.');
        text = http.responseText;
      }

      parser = new DOMParser();
      xml = parser.parseFromString(text, "text/xml");

      wNodes = xml.getElementsByTagName('width');
      wNode = wNodes[0].childNodes[0];
      hNodes = xml.getElementsByTagName('height');
      hNode = hNodes[0].childNodes[0];
      w = parseInt(wNode.nodeValue, 10);
      h = parseInt(hNode.nodeValue, 10);
    } catch (details) {
      throw "Exception: Can't set width and height when image doesn't exist";
    }

    $.TileSource.call(this, w, h, tileSize, tileOverlap, minLev, maxLev);
  };
  $.extend($.DjTileSource.prototype, $.TileSource.prototype, $.DjTileUrlBehavior);

  $.CalculatedDjTileSource = function(djatoka, imageID, width, height) {
    var tileOverlap = 0;
    var tileSize = 256;
    var text, xml, minLev, maxLev; // handled in TileSource
    var w = parseInt(width,10);
    var h = parseInt(height,10);
    this.baseURL = djatoka + "zoom/";
    this.imageID = imageID;

    $.TileSource.call(this, width, height, tileSize, tileOverlap, minLev, maxLev);
  };

  $.extend($.CalculatedDjTileSource.prototype, $.TileSource.prototype, $.DjTileUrlBehavior);
}(OpenSeadragon));