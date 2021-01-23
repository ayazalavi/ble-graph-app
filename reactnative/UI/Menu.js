import React from 'react';
import {
  Menu,
  MenuOptions,
  MenuOption,
  MenuTrigger,
} from 'react-native-popup-menu';
import Icon from 'react-native-vector-icons/MaterialIcons';

export const options = ['Switch View', 'Export', 'Clear', 'Settings'];

const MenuUI = ({callback}) => {
  return (
    <>
      {options.length > 0 && (
        <Menu onSelect={(value) => callback(value)}>
          <MenuTrigger style={{marginRight: 10}}>
            <Icon name="list" size={40} color="#ffffff" />
          </MenuTrigger>
          <MenuOptions>
            {options.map((value, index) => (
              <MenuOption value={index} text={value} key={index} />
            ))}
          </MenuOptions>
        </Menu>
      )}
    </>
  );
};

export default MenuUI;
