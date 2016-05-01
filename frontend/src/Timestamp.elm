module Timestamp where

import Native.Timestamp

type alias Timestamp = Int
type alias Timezone = String
type alias Format = String

format : Timestamp -> Format -> String
format = Native.Timestamp.format

tzFormat : Timezone -> Timestamp -> Format -> String
tzFormat = Native.Timestamp.formatWithTimezone
