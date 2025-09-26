block data options:

 - `level`: topojson js to use. (`level`.map.js file will be used if exists)
   - it can contain folder path such as `county/臺北市`.
   - for simplicity, the last part of level after splitted by `/` will be considered as name prefix.
     for example, the `臺北市` part of `county/臺北市` will be appended to data name field
     when trying to match against feature names.
