/* eslint-disable import/no-commonjs */

import $ from 'jquery';

// Fail tests for unmocked requests
$.ajax = () => {
  throw new Error(
    'Unexpected unmocked jQuery.ajax() call! Make sure to mock jQuery.ajax() in tests.',
  );
};

// jquery is not an ES6 module
module.exports = $;
