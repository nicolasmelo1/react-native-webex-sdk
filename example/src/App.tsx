import React, { useEffect } from 'react'
import { Text } from 'react-native'
import WebexSDKModule from 'react-native-webex-sdk'

const App = () => {
  useEffect(() => {
    console.log(WebexSDKModule)
  })

  return <Text>
    Hello World
  </Text>
}

export default App
