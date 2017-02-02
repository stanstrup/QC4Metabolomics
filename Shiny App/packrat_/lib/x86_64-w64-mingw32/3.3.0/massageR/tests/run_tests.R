if(require("RUnit", quietly=TRUE)) {
  
  
  

test.suite <- defineTestSuite("tests",
                              dirs = file.path("/")
                              )

test.result <- runTestSuite(test.suite)

printTextProtocol(test.result)





} else {
  warning("cannot run unit tests -- package RUnit is not available")
}

