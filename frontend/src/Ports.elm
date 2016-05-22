port module Ports exposing (path, pushPath, timestamps, timezones, notifications, notify)

import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Notification)


port path : (String -> msg) -> Sub msg


port pushPath : String -> Cmd msg


port timestamps : (Timestamp -> msg) -> Sub msg


port timezones : (Timezone -> msg) -> Sub msg


port notifications : (Notification -> msg) -> Sub msg


port notify : Notification -> Cmd msg
