port module Ports exposing (path, pushPath, timestamps, timezones)

import Timestamp exposing (Timestamp, Timezone)


port path : (String -> msg) -> Sub msg


port pushPath : String -> Cmd msg


port timestamps : (Timestamp -> msg) -> Sub msg


port timezones : (Timezone -> msg) -> Sub msg
