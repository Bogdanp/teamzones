module Timestamp exposing (..)

import Native.Timestamp
import Regex exposing (HowMany(..), regex, replace)
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


showTimezone : Timezone -> String
showTimezone =
    replace All (regex "_") (\_ -> " ")


currentDay : Timezone -> Int
currentDay =
    Native.Timestamp.currentDay


currentHour : Timezone -> Int
currentHour =
    Native.Timestamp.currentHour
