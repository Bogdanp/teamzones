port module Ports exposing (timestamps, timezones, newMembers, notifications, notify)

import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Notification, ContextUser)


port timestamps : (Timestamp -> msg) -> Sub msg


port timezones : (Timezone -> msg) -> Sub msg


port notifications : (Notification -> msg) -> Sub msg


port notify : Notification -> Cmd msg


port newMembers : (ContextUser -> msg) -> Sub msg
