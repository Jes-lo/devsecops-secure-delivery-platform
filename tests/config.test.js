const test = require('node:test');
const assert = require('node:assert/strict');

const {
  DEFAULT_PORT,
  resolvePort
} = require('../src/config');

test('resolvePort uses the default port when PORT is undefined', () => {
  assert.equal(resolvePort(undefined), DEFAULT_PORT);
});

test('resolvePort accepts a valid numeric port', () => {
  assert.equal(resolvePort('8080'), 8080);
});

test('resolvePort rejects a non-numeric port', () => {
  assert.throws(
    () => resolvePort('3000abc'),
    /PORT must be an integer between 1 and 65535/
  );
});

test('resolvePort rejects port zero', () => {
  assert.throws(
    () => resolvePort('0'),
    /PORT must be an integer between 1 and 65535/
  );
});

test('resolvePort rejects ports above 65535', () => {
  assert.throws(
    () => resolvePort('65536'),
    /PORT must be an integer between 1 and 65535/
  );
});
