const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

// read .env (if it exists)
dotenv.config();

// read env-example
const examplePath = path.resolve(process.cwd(), 'env-example');
const example = dotenv.parse(fs.readFileSync(examplePath));
const exampleKeys = Object.keys(example);

// global constants for host envs
exampleKeys
  .filter(k => k.endsWith('_HOST'))
  .forEach(key => {
    if (key.startsWith('http')) {
      global[key] = process.env[key];
    } else if (key.match(/localhost|127\.0\.0\.1/)) {
      global[key] = `http://${process.env[key]}`;
    } else {
      global[key] = `https://${process.env[key]}`;
    }
  });

// global constants for test fixtures
exampleKeys
  .filter(k => k.startsWith('TEST_'))
  .forEach(key => {
    global[key] = process.env[key];
  });

// per test config
global.beforeEach(() => {
  global.USER_AGENT = `MetaPrxOrg/2.0.0 ${expect.getState().currentTestName}`;
});
