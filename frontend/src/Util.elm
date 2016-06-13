module Util exposing (..)

import Date exposing (Date, Month(..), day, month, year)
import Html exposing (Html, a, text)
import Html.Attributes exposing (href)
import Html.Events exposing (onWithOptions)
import Json.Decode as Json
import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (AnchorTo)


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


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


(?>) : Maybe a -> a -> a
(?>) =
    flip Maybe.withDefault


(?|) : String -> String -> String
(?|) a b =
    if a == "" then
        b
    else
        a
