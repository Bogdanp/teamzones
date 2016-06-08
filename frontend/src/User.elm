module User exposing (isOffline, initials, initialsColor)

import Bitwise
import Char
import String
import Timestamp exposing (Timestamp, Timezone, currentHour, currentDay, offset)
import Types exposing (User)


isOffline : Timestamp -> User -> Bool
isOffline now { timezone, workdays } =
    let
        day =
            case currentDay timezone now of
                1 ->
                    workdays.monday

                2 ->
                    workdays.tuesday

                3 ->
                    workdays.wednesday

                4 ->
                    workdays.thursday

                5 ->
                    workdays.friday

                6 ->
                    workdays.saturday

                7 ->
                    workdays.sunday

                _ ->
                    Debug.crash "isOffline: invalid day"

        hour =
            currentHour timezone now
    in
        day.start == 0 || day.end == 0 || not (hour >= day.start && hour < day.end)


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
