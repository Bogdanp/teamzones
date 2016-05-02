module Util where

import Char
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


initialsColor : String -> String
initialsColor initials =
  String.toList initials
    |> List.repeat 3
    |> List.concat
    |> List.take 3
    |> List.map (Char.toCode >> max 17 >> min 99 >> toHex)
    |> String.join ""
    |> ((++) "#")


toHex : Int -> String
toHex n =
  let
    toChar n =
      case n of
        15 -> 'F'
        14 -> 'E'
        13 -> 'D'
        12 -> 'C'
        11 -> 'B'
        10 -> 'A'
        9  -> '9'
        8  -> '8'
        7  -> '7'
        6  -> '6'
        5  -> '5'
        4  -> '4'
        3  -> '3'
        2  -> '2'
        1  -> '1'
        0  -> '0'
        _  -> Debug.crash "Invalid number passed to toChar"

    toHex' n acc =
      if n < 16 then
        String.cons (toChar n) acc
      else
        toHex' (n // 16) (String.cons (toChar (n `rem` 16)) acc)
  in
    toHex' n ""

time : Timezone -> Timestamp -> Html
time tz = Timestamp.tzFormat tz "h:mmA" >> text
