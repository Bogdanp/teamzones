module Components.TimePicker.Time exposing (Period(..), Time, compare, defaultTime, parse, toString, zero)

import Combine exposing (Parser, choice, end, maybe, or, regex, string, succeed)
import Combine.Char exposing (char)
import Combine.Infix exposing ((<$>), (<*>), (<*), (*>))
import Combine.Num exposing (digit)
import String


type Period
    = AM
    | PM


type alias Time =
    ( Int, Int, Period )


compare : Time -> Time -> Order
compare a b =
    case ( a, b ) of
        ( ( _, _, AM ), ( _, _, PM ) ) ->
            LT

        ( ( _, _, PM ), ( _, _, AM ) ) ->
            GT

        ( ( ha, ma, _ ), ( hb, mb, _ ) ) ->
            Basics.compare ( ha, ma ) ( hb, mb )


defaultTime : Time
defaultTime =
    ( 12, 0, PM )


zero : Time
zero =
    ( 0, 0, AM )


parse : String -> Maybe Time
parse =
    Combine.parse time >> fst >> Result.toMaybe


toString : Time -> String
toString ( h, m, p ) =
    Basics.toString h ++ ":" ++ numToString m ++ periodToString p


ws : Parser String
ws =
    regex " *"


num : Int -> Maybe Int -> Int
num a b =
    case b of
        Nothing ->
            a

        Just b ->
            a * 10 + b


hour : Parser Int
hour =
    let
        toHour a b =
            num a b
                |> min 24
                |> max 0
    in
        toHour
            <$> digit
            <*> maybe digit


minute : Parser Int
minute =
    let
        toMinute a b =
            num a b
                |> min 60
                |> max 0
                |> flip rem 60
    in
        toMinute
            <$> digit
            <*> maybe digit


period : Parser Period
period =
    let
        period s =
            case String.toLower s of
                "pm" ->
                    PM

                _ ->
                    AM
    in
        period
            <$> choice [ string "am", string "AM", string "pm", string "PM" ]
            `or` succeed AM


time : Parser Time
time =
    let
        hourOnly =
            (\h p -> ( h, 0, p ))
                <$> hour
                <*> (ws *> period)

        fullTime =
            (,,)
                <$> (hour <* char ':')
                <*> minute
                <*> (ws *> period)

        postProcess ( h, m, p ) =
            if h > 12 then
                postProcess ( h % 12, m, PM )
            else if h == 0 then
                ( 12, m, AM )
            else
                ( h, m, p )
    in
        postProcess <$> choice [ fullTime, hourOnly ] <* end


numToString : Int -> String
numToString n =
    if n < 10 then
        "0" ++ Basics.toString n
    else
        Basics.toString n


periodToString : Period -> String
periodToString p =
    case p of
        AM ->
            "AM"

        PM ->
            "PM"
