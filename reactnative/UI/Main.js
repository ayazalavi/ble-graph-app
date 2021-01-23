import React from 'react';
import {useState} from 'react';
import Menu, {options} from './Menu';
import ListScreen from './List';
import GraphScreen from './Graph';
import BLE from '../modules/BLE';
import {useEffect} from 'react/cjs/react.development';
import {DeviceEventEmitter, AppState, Text} from 'react-native';
import IdleTimerManager from 'react-native-idle-timer';
import {graphStyles} from '../modules/styles';

import {
  getData,
  getObject,
  SAMPLE_KEY,
  PING_KEY,
  DATA_KEY,
  save,
  storeObject,
  NEW_DATA,
  exportData,
  clearData,
  CLEAR_DATA,
  DATA_POINTS_KEY,
} from '../modules/DataModule';
let int_, ble;
const MainScreen = ({navigation}) => {
  const [showList, setShowList] = useState(true);
  const [setInterval_, setSetInterval_] = useState(false);
  const [showCallback, setShowCallback] = useState(0);
  const [data, setData] = useState([]);
  const [sample, setSample] = useState(1);
  const [ping, setPing] = useState(1000);
  const [datapoints, setDatapoints] = useState(10);
  const [callstoreDataFunc, setCallStoreDataFunc] = useState(false);

  const _handleAppStateChange = (nextAppState) => {
    // console.log('state: ', nextAppState, data_.data.length);
    if (nextAppState === 'inactive') {
      setCallStoreDataFunc(true);
    }
  };
  console.log('main, data: ', data ? data.length : 0, ', ping: ' + ping);
  const onConnected = (initialData) => {
    //console.log('on interval, ' + ble.ping_frequency);
    if (int_) clearInterval(int_);
    int_ = setInterval(() => {
      if (ble.connected) {
        // console.log('requesting data: ');
        ble
          .request()
          .then(async (data1) => {
            const data2 = JSON.parse(data1);
            // console.log('data received: ' + initialData.length);
            let timestamp = Date.now();
            for (var key in data2) {
              data2[key].push(timestamp);
              initialData.unshift(data2[key]);
              DeviceEventEmitter.emit(NEW_DATA, data2[key]);
            }
            setData((oldvalue) => initialData.concat([]));

            /* setData((oldValue) => ({
              sample: oldValue.sample,
              ping: oldValue.ping,
              datapoints: oldValue.datapoints,
              data: initialData,
            })); */
          })
          .catch((err) => {
            if (err.message === 'Operation was rejected') {
              clearInterval(int_);
              alert(err.message);
            }
          });
      } else {
        setData((oldValue) => ({...oldValue}));
        console.log('ble not connected so far');
      }
    }, parseFloat(ble.ping_frequency));
  };
  if (callstoreDataFunc) {
    storeObject(DATA_KEY, data).then(() => {
      console.log('data stored: ' + data.length);
      setCallStoreDataFunc(false);
    });
  }
  if (ble && setInterval_) {
    setSetInterval_(false);
    onConnected(data.concat([]));
    AppState.removeEventListener('change', _handleAppStateChange);
    AppState.addEventListener('change', _handleAppStateChange);
  }
  useEffect(() => {
    Promise.all([
      getData(SAMPLE_KEY),
      getData(PING_KEY),
      getObject(DATA_POINTS_KEY),
      getObject(DATA_KEY),
    ]).then(([sample_, ping_, datapoints_, data_]) => {
      //console.log('old data: ', data_.length);
      //  IdleTimerManager.setIdleTimerDisabled(true);
      if (!data_) data_ = [];
      if (!ping_) ping_ = 1000;
      if (!sample_) sample_ = 1;
      if (!datapoints_) datapoints_ = 10;
      setSample(sample_);
      setPing(ping_);
      setDatapoints(datapoints_);
      setData(data_.concat(data));
      // console.log(data_.length, data.length);
      /* if (data)
        data
          .slice(0, 50)
          .forEach((val) => DeviceEventEmitter.emit(NEW_DATA, val)); */

      ble = new BLE(ping_, sample);
    });

    const unsubscribe = navigation.addListener('focus', (e) => {
      //   console.log('focus');
      Promise.all([
        getData(SAMPLE_KEY),
        getData(PING_KEY),
        getObject(DATA_POINTS_KEY),
        getObject(DATA_KEY),
      ]).then(([sample_, ping_, datapoints_, data_]) => {
        if (!data_) data_ = [];
        if (!ping_) ping_ = 1000;
        if (!sample_) sample_ = 1;
        if (!datapoints_) datapoints_ = 10;
        // console.log(
        //   'on data, ' + ping + ', ' + data_.data.length + ', ' + data.length,
        // );
        // console.log(data_.length, data.length);

        setSample(sample_);
        setPing(ping_);
        setDatapoints(datapoints_);
        setData(data_.concat(data));
        if (ble) {
          ble.setPing(ping_);
          ble.sample = sample_;
          setSetInterval_(true);
        }
      });
    });
    const unsubscribe2 = navigation.addListener('blur', (e) => {
      console.log('blur');
      setCallStoreDataFunc(true);
      if (int_) clearInterval(int_);
    });

    return function cleanup() {
      console.log('uneffect');
      if (ble) ble.disconnect();
      unsubscribe();
      unsubscribe2();
      //storeObject(DATA_KEY, data);
      //AppState.removeEventListener('change', _handleAppStateChange);
      // IdleTimerManager.setIdleTimerDisabled(false);
    };
  }, []);
  const clear_data = (message) => {
    alert(message);
    onConnected([]);
    clearData();
    DeviceEventEmitter.emit(CLEAR_DATA, '');
    setData([]);
  };

  if (showCallback > 0) {
    setShowCallback(0);
    if (showCallback === 1) {
      exportData(data, () => {
        clear_data('Data exported successfully');
      });
    } else {
      clear_data('Data cleared successfully');
    }
  }

  React.useLayoutEffect(() => {
    const menuSelected = (value) => {
      if (options[value] === 'Settings') navigation.navigate('Settings');
      else if (options[value] === 'Switch View') setShowList(!showList);
      else if (options[value] === 'Export') setShowCallback(1);
      else if (options[value] === 'Clear') setShowCallback(2);
    };

    navigation.setOptions({
      headerRight: () => <Menu callback={menuSelected} />,
      headerTitle: (props) => <Status {...props} />,
    });
  }, [navigation, showList, setInterval_]);

  function Status() {
    return (
      <>
        <Text style={graphStyles.buttonType1}>Sample rate: {sample}</Text>
        <Text style={graphStyles.buttonType1}>Ping Frequency: {ping}</Text>
        <Text style={graphStyles.buttonType1}>
          Connectivity:{' '}
          {!ble
            ? 'Connecting'
            : ble.connected
            ? 'Connected'
            : ble.device
            ? 'Disconnected'
            : 'Connecting'}
        </Text>
      </>
    );
  }

  const fetchData = (start, end) => {
    //  console.log('request data: ' + data_.data.length);
    if (!data) return [];
    return data.slice(start, end);
  };
  return (
    <>
      {showList && <ListScreen key={0} fetchData={fetchData} />}
      {!showList && (
        <GraphScreen key={1} fetchData={fetchData} dataPoints={datapoints} />
      )}
    </>
  );
};

export default MainScreen;
