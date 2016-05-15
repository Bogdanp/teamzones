module User exposing (isOffline)

import Timestamp exposing (Timezone, currentHour, currentDay)
import Types exposing (User)


isOffline : User -> Bool
isOffline { timezone, workdays } =
    let
        accessor =
            case currentDay timezone of
                1 ->
                    .monday

                2 ->
                    .tuesday

                3 ->
                    .wednesday

                4 ->
                    .thursday

                5 ->
                    .friday

                6 ->
                    .saturday

                7 ->
                    .sunday

                _ ->
                    Debug.crash "invalid day"

        day =
            accessor workdays

        hour =
            currentHour timezone
    in
        day.start == 0 || day.end == 0 || not (hour >= day.start && hour < day.end)
