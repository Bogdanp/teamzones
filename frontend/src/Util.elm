module Util where

import Html exposing (Html, text)
import String

import Timestamp exposing (Timestamp, Timezone)


initials : String -> String
initials name =
  name
    |> String.split " "
    |> List.take 2
    |> List.map (fst << Maybe.withDefault (' ', "") << String.uncons)
    |> String.fromList
    |> String.trimRight


time : Timezone -> Timestamp -> Html
time tz = Timestamp.tzFormat tz "h:mmA" >> text
