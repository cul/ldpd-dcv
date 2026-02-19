import { dateWidgetReady } from './dcv.date-range';
import { mapReady } from './dcv.map';
import { searchResultsReady } from './dcv.search_results';
import { synchronizerReady } from './dcv.synchronizer';
import { videoReady } from './dcv.video';
/************
 * ON READY *
 ************/

$(() => {
  mapReady();
  searchResultsReady();
  synchronizerReady();
  videoReady();
});
