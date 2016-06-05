module Util exposing (..)

import Bitwise
import Char
import Date exposing (Date, Month(..), day, month, year)
import Html exposing (Html, a, text)
import Html.Attributes exposing (href)
import Html.Events exposing (onWithOptions)
import Json.Decode as Json
import Routes exposing (Sitemap(..))
import String
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (AnchorTo)


initials : String -> String
initials name =
    name
        |> String.split " "
        |> List.take 2
        |> List.filterMap (Maybe.map fst << String.uncons)
        |> String.fromList


initialsColor : String -> String
initialsColor initials =
    let
        hash i c =
            toFloat c
                * 0.6180339
                * (2 ^ 54)
                |> floor
                |> flip Bitwise.shiftLeft i
                |> flip Bitwise.shiftRight 52
                |> flip rem 256
                |> abs

        hexFromChar i c =
            Char.toCode c
                |> hash i
                |> max 16
                |> hexFromInt
    in
        String.toList initials
            |> List.repeat 3
            |> List.concat
            |> List.take 3
            |> List.indexedMap hexFromChar
            |> String.join ""
            |> ((++) "#")


hexFromInt : Int -> String
hexFromInt n =
    let
        toChar n =
            case n of
                15 ->
                    'F'

                14 ->
                    'E'

                13 ->
                    'D'

                12 ->
                    'C'

                11 ->
                    'B'

                10 ->
                    'A'

                9 ->
                    '9'

                8 ->
                    '8'

                7 ->
                    '7'

                6 ->
                    '6'

                5 ->
                    '5'

                4 ->
                    '4'

                3 ->
                    '3'

                2 ->
                    '2'

                1 ->
                    '1'

                0 ->
                    '0'

                _ ->
                    Debug.crash "Invalid number passed to toChar"

        hexFromInt' n acc =
            if n < 16 then
                String.cons (toChar n) acc
            else
                hexFromInt' (n // 16) (String.cons (toChar (n `rem` 16)) acc)
    in
        hexFromInt' n ""


time : Timezone -> Timestamp -> Html msg
time tz =
    Timestamp.tzFormat tz "h:mmA" >> text


dateTuple : Date -> ( Int, Int, Int )
dateTuple date =
    ( year date, monthToInt <| month date, day date )


monthToInt : Month -> Int
monthToInt month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


on' : String -> msg -> Html.Attribute msg
on' event msg =
    let
        options =
            { stopPropagation = True
            , preventDefault = True
            }
    in
        onWithOptions event options (Json.succeed msg)


anchorTo : (Sitemap -> msg) -> AnchorTo msg
anchorTo f route attrs =
    a ([ on' "click" (f route), href (Routes.toString route) ] ++ attrs)


boolFromMaybe : Maybe a -> Bool
boolFromMaybe ma =
    Maybe.map (always True) ma ?> False


ttl : Float -> String
ttl seconds =
    let
        hours =
            let
                h =
                    toString (floor (seconds / 3600))
            in
                if h == "1" then
                    h ++ " hour"
                else
                    h ++ " hours"

        minutes =
            let
                m =
                    toString (floor seconds `rem` 3600 // 60)
            in
                if m == "1" then
                    m ++ " minute"
                else
                    m ++ " minutes"
    in
        if hours == "0 hours" then
            minutes
        else
            hours ++ " and " ++ minutes


unsafeDate : String -> Date
unsafeDate date =
    case Date.fromString date of
        Err e ->
            Debug.crash ("unsafeDate: failed to parse date:" ++ e)

        Ok date ->
            date


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


(?>) : Maybe a -> a -> a
(?>) =
    flip Maybe.withDefault


(??) : Maybe a -> Maybe a -> Maybe a
(??) mv md =
    case mv of
        Nothing ->
            md

        v ->
            v
