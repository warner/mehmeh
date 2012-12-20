
// use <body onload="loaded()"> to start the collectors after sjcl is loaded
// then run test() from the JS console
function loaded() {
    var intervalID;
    function checkReady() {
        var e = document.getElementById("entropy-progress");
        if (sjcl.random.isReady()) {
            e.textContent = "Ready!";
            window.clearInterval(intervalID);
        } else{
            var progress = sjcl.random.getProgress();
            e.textContent = progress;
        }
    }
    sjcl.random.startCollectors();
    intervalID = window.setInterval(checkReady, 0.5);
}
