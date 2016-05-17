module User exposing (isOffline)

import Timestamp exposing (Timestamp, Timezone, currentHour, currentDay)
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
