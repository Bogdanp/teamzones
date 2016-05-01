module Timestamp where

import Native.Timestamp

type alias Timestamp = Int
type alias Timezone = String
type alias Format = String

format : Format -> Timestamp -> String
format = Native.Timestamp.format

tzFormat : Timezone -> Format -> Timestamp -> String
tzFormat = Native.Timestamp.formatWithTimezone
