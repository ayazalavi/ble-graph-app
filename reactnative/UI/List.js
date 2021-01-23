import React, {useState, useEffect, useCallback} from 'react';
import {useRef} from 'react';
import {View, Text, DeviceEventEmitter} from 'react-native';
import {list} from '../modules/styles';
import {
  getObject,
  DATA_KEY,
  dataArray,
  NEW_DATA,
  CLEAR_DATA,
} from '../modules/DataModule';
import InfiniteScroll from 'react-native-infinite-scrolling';

const headers = [
  'Acc. X',
  'Acc. Y',
  'Acc. Z',
  'Gyro X',
  'Gyro Y',
  'Gyro Z',
  'Mag. X',
  'Mag. Y',
  'Mag. Z',
  'Alt.',
];
const ListScreen = ({navigation, fetchData}) => {
  const [current, setCurrent] = useState([]);
  const getMoreData = () => {
    const data = fetchData(current.length, current.length + 50);
    let data2 = data.concat([]);
    //console.log('more data: ' + data.length);
    if (data.length > 0) {
      setCurrent((value) => value.concat(data2));
    }
  };
  //console.log('total: ' + current.length);
  const new_data = (data) => {
    let data2 = data.concat([]);
    setCurrent((value) => {
      value.unshift(data2);
      return value.concat([]);
    });
  };

  const remove_data = (value) => {
    setCurrent([]);
  };

  useEffect(() => {
    const eventListener = DeviceEventEmitter.addListener(NEW_DATA, new_data);
    const eventListener2 = DeviceEventEmitter.addListener(
      CLEAR_DATA,
      remove_data,
    );
    return function cleanData() {
      eventListener.remove();
      eventListener2.remove();
    };
  }, []);

  const renderData = (data) => {
    //console.log(data);
    return (
      <View style={list.main}>
        {data.item.slice(0, 10).map((value2, index2) => (
          <Text style={list.child} key={index2}>
            {value2}
          </Text>
        ))}
      </View>
    );
  };
  return (
    <View style={list.scrollview}>
      <View style={list.mainheader}>
        {headers.map((value2, index2) => (
          <Text style={list.childheader} key={index2}>
            {value2}
          </Text>
        ))}
      </View>
      <InfiniteScroll
        renderData={renderData}
        data={current}
        loadMore={getMoreData}
        style={list.scrollview}
      />
    </View>
  );
};

export default ListScreen;
