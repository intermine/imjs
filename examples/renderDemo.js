// thanks mozilla for helping me when I'm too lazy to write basic xhr code
//https://developer.mozilla.org/en-US/docs/Web/Guide/AJAX/Getting_Started

//we'll use this to GET stuff.
function makeRequest(urlToGet) {
  var httpRequest = new XMLHttpRequest();
  //rudimentary error handling
  if (!httpRequest) {
    handleError("Error loading issues");
    return false;
  }
  httpRequest.onreadystatechange = handleResults;
  httpRequest.open('GET', urlToGet);
  httpRequest.send();
}
//cool. Let's go through all result we're given and add them
// to the screen unless they're already present.
function handleResults(event) {
  if (event.target.readyState === XMLHttpRequest.DONE) {
    if (event.target.status === 200) {
      printResults(event.target.responseText)
    } else {
      handleError('There was a problem with the request.');
    }
  }
}

/*
Add the script to the screen, all pretty and highlighted, AND make it run.
*/
function printResults(results){
  //add to the screen
  var demoDiv = document.getElementById("demos");
  var formattedResults = Prism.highlight(results, Prism.languages.javascript, 'javascript');
  demoDiv.innerHTML = formattedResults;
  //make the script run.
  document.getElementById("demoScript").innerHTML = results;
}

var fileToGet = window.location.search.split("=")[1];

makeRequest("examples-src/" + fileToGet + ".js");
