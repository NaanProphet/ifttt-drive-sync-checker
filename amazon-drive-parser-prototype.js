// Reads a public Amazon Cloud Drive folder and return the number of files inside.
// Amazon page is rendered using JS, hence the need for a phantomjs script to 
// actually populate the page's content. Basically hacks/scrubs the file count that
// is displayed at the top of the page.

// Usage: phantomjs amazon-cloud-parser-example.js

"use strict";
var page = require('webpage').create();

const amazonURL = "" // <-- specify public URL to Amazon folder here

page.onConsoleMessage = function(msg) {
  console.log(msg);
};

// suppress TypeError messages that get thrown during tag searching
page.onError = function(msg, trace) {
  var msgStack = ['ERROR: ' + msg];
  if (trace && trace.length) {
    msgStack.push('TRACE:');
    trace.forEach(function(t) {
      msgStack.push(' -> ' + t.file + ': ' + t.line + (t.function ? ' (in function "' + t.function+'")' : ''));
    });
  }
  // uncomment to log into the console
  // console.error(msgStack.join('\n'));
};

page.open(amazonURL, function(status) {
  if (status === "success") {
    var numTracks = page.evaluate(function() {
      // search for the 'count' class that decorates the number of files printed on the page
      return [].map.call(document.getElementsByClassName('count'), function(elem) {
        var spanTag = elem.innerHTML;
				console.log(spanTag)
        //determine start-pos and end-pos of desired substring, and then get it
        var startPos = spanTag.indexOf("<span>") + "<span>".length;
        var endPos = spanTag.indexOf("</span>");
        var targetText = spanTag.substring(startPos, endPos).trim();
        return targetText;
      });
    });
    console.log(numTracks);
    phantom.exit(0);
  } else {
    phantom.exit(-1);
  }
});
