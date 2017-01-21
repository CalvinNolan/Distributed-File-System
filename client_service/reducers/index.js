import { combineReducers } from 'redux';  
import auth from './auth';
import file from './file';

const clientServiceApp = combineReducers({
  auth,
  file
});

export default clientServiceApp;
