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


defaultFormat : Timestamp -> String
defaultFormat =
    format "YYYY-MM-DD HH:mmA"


tzFormat : Timezone -> Format -> Timestamp -> String
tzFormat =
    Native.Timestamp.formatWithTimezone


offset : Timezone -> TimezoneOffset
offset =
    Native.Timestamp.offset


showTimezone : Timezone -> String
showTimezone =
    replace All (regex "_") (\_ -> " ")


currentDay : Timezone -> Timestamp -> Int
currentDay =
    Native.Timestamp.currentDay


currentHour : Timezone -> Timestamp -> Int
currentHour =
    Native.Timestamp.currentHour


fromString : String -> Timestamp
fromString =
    Native.Timestamp.fromString


isoFormat : Timestamp -> String
isoFormat =
    Native.Timestamp.isoFormat


from : Timestamp -> Timestamp -> String
from =
    Native.Timestamp.from
