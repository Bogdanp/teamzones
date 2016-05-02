module Timestamp where

import Native.Timestamp

type alias Timestamp = Int
type alias Timezone = String
type alias TimezoneOffset = Int
type alias Format = String

format : Format -> Timestamp -> String
format = Native.Timestamp.format

tzFormat : Timezone -> Format -> Timestamp -> String
tzFormat = Native.Timestamp.formatWithTimezone

offset : Timezone -> TimezoneOffset
offset = Native.Timestamp.offset
