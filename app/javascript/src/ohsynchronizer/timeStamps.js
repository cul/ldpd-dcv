
const twoDigits = function(value, frac) {
	return Number(value).toLocaleString(undefined, {minimumIntegerDigits: 2, maximumFractionDigits: frac, minimumFractionDigits: frac});
}

export const secondsAsTimestamp = function(time, frac = 3) {
	var minutes = Math.floor(time / 60);
	var seconds = (time - minutes * 60).toFixed(3);
	var hours = Math.floor(minutes / 60);
	if (hours > 0) minutes = minutes - 60 * hours;
	return twoDigits(hours, 0) + ":" + twoDigits(minutes, 0) + ":" + twoDigits(seconds, frac);
}

export const timestampToDate = function(timestamp) {
	var parts = timestamp.split(/[:\.]/);
	var result = new Date();
	result.setHours(parts[0]);
	result.setMinutes(parts[1]);
	result.setSeconds(parts[2]);
	result.setMilliseconds(parts[3]);
	return result;
}

export const timestampAsSeconds = function(timestamp) {
	var parts = timestamp.split(/[:\.]/);
	var result = parseInt(parts[0]) * 3600;
	result += parseInt(parts[1]) * 60;
	result += parseInt(parts[2]);
	result += parseInt(parts[3])/1000;
	return result;
}
