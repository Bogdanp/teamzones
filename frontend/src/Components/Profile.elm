module Components.Profile exposing (Model, Msg, update, view)

import Components.Page exposing (page)
import Html exposing (..)
import Html.Attributes exposing (..)
import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone, offset)
import Types exposing (AnchorTo, User, Workday)
import User exposing (isOffline)
import Util exposing ((=>), initials, initialsColor)


type Msg
    = RouteTo Sitemap


type alias Model =
    { now : Timestamp
    , user : User
    , currentUser : User
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RouteTo route ->
            ( model, Routes.push route )


view : Model -> Html Msg
view { now, user, currentUser } =
    let
        offline =
            isOffline now user
    in
        page user.fullName
            [ div [ class "profile-page" ]
                [ div [ class "profile-sidebar" ]
                    [ div [ class "user-profile" ]
                        [ avatar user
                        , h3 [] [ Util.time user.timezone now ]
                        , h6 []
                            [ if offline then
                                text "Offline"
                              else
                                text "Online"
                            ]
                        ]
                    ]
                , div [ class "profile-content" ]
                    [ workdays user currentUser ]
                ]
            ]


avatar : User -> Html Msg
avatar user =
    let
        initials' =
            initials user.fullName

        avatar' =
            case user.avatar of
                Nothing ->
                    div
                        [ class "initials"
                        , style [ "background" => initialsColor initials' ]
                        ]
                        [ text initials' ]

                Just uri ->
                    div []
                        [ img
                            [ src uri
                            , title user.fullName
                            , alt initials'
                            ]
                            []
                        ]
    in
        div [ class "avatar" ] [ avatar' ]


workdays : User -> User -> Html Msg
workdays user currentUser =
    let
        uOffset =
            offset user.timezone

        cOffset =
            offset currentUser.timezone

        adjust h =
            if h == 0 then
                0
            else
                let
                    delta =
                        (cOffset - uOffset) // 60

                    delta' =
                        if cOffset > 0 && uOffset < 0 then
                            h + delta
                        else if cOffset < 0 && uOffset > 0 then
                            h + delta
                        else
                            h - delta

                    delta'' =
                        if delta' < 0 then
                            24 + delta'
                        else
                            delta'
                in
                    case delta'' `rem` 24 of
                        0 ->
                            24

                        x ->
                            x

        hour h =
            td []
                [ text <| showHour h
                , if h /= 0 then
                    strong [] [ text <| " (" ++ showHour (adjust h) ++ ")" ]
                  else
                    text ""
                ]

        workday name d =
            tr []
                [ td [] [ text name ]
                , hour d.start
                , hour d.end
                ]
    in
        div []
            [ h4 [] [ text "Workdays" ]
            , table []
                [ thead []
                    [ tr []
                        [ td [] [ text "Day" ]
                        , td [] [ text "From" ]
                        , td [] [ text "Until" ]
                        ]
                    ]
                , tbody []
                    [ workday "Monday" user.workdays.monday
                    , workday "Tuesday" user.workdays.tuesday
                    , workday "Wednesday" user.workdays.wednesday
                    , workday "Thursday" user.workdays.thursday
                    , workday "Friday" user.workdays.friday
                    , workday "Saturday" user.workdays.saturday
                    , workday "Sunday" user.workdays.sunday
                    ]
                ]
            , p [ class "small" ]
                [ strong [] [ text "Note:" ]
                , text " values in parentheses represent your local time."
                ]
            ]


showHour : Int -> String
showHour h =
    case h of
        1 ->
            "1AM"

        2 ->
            "2AM"

        3 ->
            "3AM"

        4 ->
            "4AM"

        5 ->
            "5AM"

        6 ->
            "6AM"

        7 ->
            "7AM"

        8 ->
            "8AM"

        9 ->
            "9AM"

        10 ->
            "10AM"

        11 ->
            "11AM"

        12 ->
            "12PM"

        13 ->
            "1PM"

        14 ->
            "2PM"

        15 ->
            "3PM"

        16 ->
            "4PM"

        17 ->
            "5PM"

        18 ->
            "6PM"

        19 ->
            "7PM"

        20 ->
            "8PM"

        21 ->
            "9PM"

        22 ->
            "10PM"

        23 ->
            "11PM"

        24 ->
            "12AM"

        _ ->
            "-"
