import React from 'react'
import { render } from 'react-dom'
import { createStore, applyMiddleware } from 'redux'
import { Provider } from 'react-redux'
import App from './components/App'
import clientServiceApp from './reducers'
import thunkMiddleware from 'redux-thunk'

const store = createStore(
    clientServiceApp, 
    {},
    applyMiddleware(
      thunkMiddleware
    )
  );

render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById('root')
)