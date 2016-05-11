module Timestamp exposing (..)

import Native.Timestamp
import Time


type alias Timestamp =
    Time.Time


type alias Timezone =
    String


type alias TimezoneOffset =
    Int


type alias Format =
    String


format : Format -> Timestamp -> String
format =
    Native.Timestamp.format


tzFormat : Timezone -> Format -> Timestamp -> String
tzFormat =
    Native.Timestamp.formatWithTimezone


offset : Timezone -> TimezoneOffset
offset =
    Native.Timestamp.offset
