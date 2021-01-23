import React, {useState, useEffect, useLayoutEffect} from 'react';
import {
  View,
  Dimensions,
  DeviceEventEmitter,
  TouchableOpacity,
  Text,
} from 'react-native';
import {LineChart} from 'react-native-chart-kit';
import {NEW_DATA, CLEAR_DATA} from '../modules/DataModule';
import {graphStyles} from '../modules/styles';
import {Button} from 'react-native-elements';

let dataPoints_;
const GraphScreen = ({navigation, fetchData, dataPoints}) => {
  const [current, setCurrent] = useState([]);
  const [graphtype, setGraphType] = useState(0);
  if (dataPoints !== dataPoints_) {
    dataPoints_ = dataPoints;
    setCurrent((oldCurrent) => fetchData(0, dataPoints));
  }

  const new_data = (data) => {
    console.log('new data' + dataPoints_);
    setCurrent((value) => {
      value.unshift(data);
      return value.slice(0, dataPoints_);
    });
  };

  const remove_data = (value) => {
    setCurrent([]);
  };
  console.log(
    'graph, ' + graphtype + ', ' + current.length + ', ' + dataPoints,
  );
  const generateData = () => {
    let labels = [];
    let dataset = [];
    let legends = [];
    let colors = ['white', 'darkblue', 'black'];
    console.log('current, ' + current.length);
    for (var i = current.length - 1; i >= 0; i--) {
      if (labels.length <= 10 && i % 10 === 0) labels.unshift(i);
      for (var j in current[i]) {
        //  console.log(`entry at [${i}][${j}]: ${current[i][j]}`);
        if (j < graphtype || j > graphtype + 2) continue;
        if (graphtype === 9 && j > graphtype) continue;
        let ind = j % 3;
        if (dataset[ind] !== undefined) {
          //  console.log(JSON.stringify(dataset));
          dataset[ind].data.push(current[i][j]);
        } else {
          dataset[ind] = {
            data: [current[i][j]],
            color: (opacity) => colors[ind],
          };
        }
      }
    }
    //console.log('dataset, ' + JSON.stringify(dataset));
    switch (graphtype) {
      case 0:
        legends = ['Acc. X', 'Acc. Y', 'Acc. Z'];
        break;
      case 3:
        legends = ['Gyro X', 'Gyro Y', 'Gyro Z'];
        break;
      case 6:
        legends = ['Mag. X', 'Mag. Y', 'Mag. Z'];
      case 9:
        legends = ['Altometer'];
        break;
    }
    // console.log('labels: ' + labels);
    // console.log('legends: ' + legends);
    //console.log('dataset: ' + dataset[0].data.length);
    return {
      labels: labels,
      datasets: dataset,
      legend: legends,
    };
  };
  useEffect(() => {
    setCurrent((oldCurrent) => fetchData(0, dataPoints));
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
  useLayoutEffect(() => {}, []);
  const AppButton = (props) => (
    <Button {...props} titleStyle={graphStyles.buttonType1} type="clear" />
  );
  return (
    <View>
      {current.length > 0 && (
        <>
          <View style={graphStyles.buttonStack}>
            <AppButton
              onPress={(e) => setGraphType(0)}
              title="Accelerometer"
              containerStyle={
                graphtype !== 0
                  ? graphStyles.buttonType
                  : graphStyles.buttonSelected
              }
            />
            <AppButton
              onPress={(e) => setGraphType(3)}
              title="Gyro"
              containerStyle={
                graphtype !== 3
                  ? graphStyles.buttonType
                  : graphStyles.buttonSelected
              }
            />
            <AppButton
              onPress={(e) => setGraphType(6)}
              title="Magnetometer"
              containerStyle={
                graphtype !== 6
                  ? graphStyles.buttonType
                  : graphStyles.buttonSelected
              }
            />
            <AppButton
              onPress={(e) => setGraphType(9)}
              title="Altometer"
              containerStyle={
                graphtype !== 9
                  ? graphStyles.buttonType
                  : graphStyles.buttonSelected
              }
            />
          </View>
          <LineChart
            data={generateData()}
            width={Dimensions.get('window').width} // from react-native
            height={Dimensions.get('window').height - 120}
            yAxisInterval={1} // optional, defaults to 1
            chartConfig={{
              backgroundColor: '#e26a00',
              backgroundGradientFrom: '#fb8c00',
              backgroundGradientTo: '#ffa726',
              decimalPlaces: 2, // optional, defaults to 2dp
              color: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,
              labelColor: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,

              propsForDots: {
                r: '0',
                strokeWidth: '2',
                stroke: '#ffa726',
              },
            }}
            bezier
          />
        </>
      )}
    </View>
  );
};

export default GraphScreen;
