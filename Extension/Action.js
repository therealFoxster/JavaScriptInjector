var Action = function() {};

Action.prototype = {
    run: function(parameters) { // Called before extension is run
        parameters.completionFunction({
            "URL": document.URL,
            "title": document.title
        });
    },
    
    finalize: function(parameters) { // Called after extension is run (iOS only)
        var code = parameters["code"];
        eval(code); // Execute code
    },
};

var ExtensionPreprocessingJS = new Action
