#require('./support/tester').run_dir(__dirname)
tester = require('./support/tester')
tester.add '../run'
tester.add '../routes'
tester.add '../helpers'
tester.add '../views'
tester.add '../sockets'
tester.add '../middleware'
#tester.add '../assets'
tester.run()