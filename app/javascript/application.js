// Entry point for the build script in your package.json
import jQuery from 'jquery';
window.jQuery = jQuery;
window.$ = jQuery;

// React
import * as React from 'react';
window.React = React;
window.useState = React.useState;
window.useEffect = React.useEffect;
window.useRef = React.useRef;
window.useMemo = React.useMemo;

// create-react-class
import createReactClass from 'create-react-class';
window.createReactClass = createReactClass;

// react-dom
import { createRoot } from 'react-dom/client';
window.createRoot = createRoot;

// regenerator-runtime
import regeneratorRuntime from 'regenerator-runtime/runtime';
window.regeneratorRuntime = regeneratorRuntime;

// hash-wasm
import { createSHA256 } from 'hash-wasm';
window.createSHA256 = createSHA256;
