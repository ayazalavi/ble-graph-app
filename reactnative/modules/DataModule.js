import AsyncStorage from '@react-native-async-storage/async-storage';
import firebase from 'firebase';
import uuid from 'react-native-uuid';

export const SAMPLE_KEY = '001';
export const PING_KEY = '002';
export const DATA_KEY = '003';
export const NEW_DATA = '004';
export const CLEAR_DATA = '005';
export const DATA_POINTS_KEY = '006';
export let dataArray = [];

export const storeData = async (key, value) => {
  try {
    await AsyncStorage.setItem(key, value);
  } catch (e) {
    alert(e);
  }
};

export const save = async (data) => {
  try {
    return await storeObject(DATA_KEY, data);
  } catch (e) {
    alert(e);
  }
};

export const clearData = async () => {
  storeObject(DATA_KEY, []);
};

export const exportData = async (data, callback) => {
  //console.log(data);
  var firebaseConfig = {
    apiKey: 'AIzaSyAmUIC04MXNMVhHWr8h847sriCkr_sGne4',
    authDomain: 'device-testing-93c0e.firebaseapp.com',
    projectId: 'device-testing-93c0e',
    storageBucket: 'device-testing-93c0e.appspot.com',
    messagingSenderId: '1090642254640',
    appId: '1:1090642254640:web:62c2312ba8f34d2dea86f5',
    measurementId: 'G-T6XQR6DR46',
  };
  if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
  } else {
    firebase.app(); // if already initialized, use that one
  }
  // Initialize Firebase
  // firebase.analytics();
  var storageRef = firebase.storage().ref();
  var blob = new Blob([JSON.stringify(data)], {type: 'application/json'});
  var mountainsRef = storageRef.child(uuid.v1() + '.json');
  mountainsRef
    .put(blob)
    .then(callback)
    .catch((err) => console.log(err));
};

export const storeObject = async (key, value) => {
  try {
    const jsonValue = JSON.stringify(value);
    await AsyncStorage.setItem(key, jsonValue);
  } catch (e) {}
};

export const getData = async (key) => {
  try {
    const value = await AsyncStorage.getItem(key);
    if (value !== null) {
      return value;
    }
  } catch (e) {
    alert(e);
  }
};

export const getObject = async (key) => {
  try {
    const jsonValue = await AsyncStorage.getItem(key);
    return jsonValue !== null ? JSON.parse(jsonValue) : null;
  } catch (e) {}
};
