module Components.Meetings exposing (Msg, Model, init, update, view)

import Components.Common exposing (heading)
import Components.Form as FC
import Components.Notifications exposing (info)
import Components.Page exposing (page)
import Components.TimePicker as TimePicker
import Components.TimePicker.Time as Time exposing (Time)
import Date exposing (Date)
import DatePicker exposing (DatePicker, defaultSettings)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck)
import Html.Lazy exposing (lazy)
import Json.Encode as Json
import Routes exposing (Sitemap(..), IntegrationsSitemap(..))
import Set exposing (Set)
import Timestamp exposing (Timestamp)
import Types exposing (AnchorTo, IntegrationStates, User)
import User
import Util exposing ((?>), (??), (=>), dateTuple)


type AttendeeState
    = None
    | Subset
    | All


type Msg
    = RouteTo Sitemap
    | ToStartDatePicker DatePicker.Msg
    | ToStartTimePicker TimePicker.Msg
    | ToEndDatePicker DatePicker.Msg
    | ToEndTimePicker TimePicker.Msg
    | CheckAll Bool
    | Check String Bool
    | Submit


type alias Context =
    { now : Timestamp
    , teamMembers : List User
    , integrationStates : IntegrationStates
    }


type alias Model =
    { startDate : Date
    , startTime : Time
    , startDatePicker : DatePicker
    , startTimePicker : TimePicker.Model
    , endDate : Date
    , endTime : Time
    , endDatePicker : DatePicker
    , endTimePicker : TimePicker.Model
    , teamMembers : List User
    , attendeeState : AttendeeState
    , attendees : Set String
    }


init : Context -> ( Model, Cmd Msg )
init { now, teamMembers, integrationStates } =
    let
        isDisabled date =
            dateTuple date < dateTuple (Date.fromTime now)

        later =
            now - (toFloat <| floor now `rem` 600000) + 900000

        startDate =
            Date.fromTime later

        startTime =
            Timestamp.format "h:mmA" later

        endDate =
            Date.fromTime <| later + 3600000

        endTime =
            Timestamp.format "h:mmA" <| later + 3600000

        ( startDatePicker, startDatePickerFx ) =
            DatePicker.init { defaultSettings | isDisabled = isDisabled, pickedDate = Just startDate }

        startTimePicker =
            TimePicker.initWithValue startTime

        ( endDatePicker, endDatePickerFx ) =
            DatePicker.init { defaultSettings | isDisabled = isDisabled, pickedDate = Just endDate }

        endTimePicker =
            TimePicker.initWithValue endTime

        model =
            { startDate = startDate
            , startTime = Time.parse startTime ?> Time.zero
            , startDatePicker = startDatePicker
            , startTimePicker = startTimePicker
            , endDate = endDate
            , endTime = Time.parse endTime ?> Time.zero
            , endDatePicker = endDatePicker
            , endTimePicker = endTimePicker
            , teamMembers = teamMembers
            , attendeeState = None
            , attendees = Set.empty
            }
    in
        if integrationStates.gCalendar then
            model
                ! [ Cmd.map ToStartDatePicker startDatePickerFx
                  , Cmd.map ToEndDatePicker endDatePickerFx
                  ]
        else
            model
                ! [ Routes.navigateTo (IntegrationsR (GCalendarR ()))
                  , info "You must connect your Google Calendar account before you can set up meetings."
                  ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ startDate, startTime, endDate, endTime } as model) =
    case msg of
        RouteTo route ->
            model ! [ Routes.navigateTo route ]

        ToStartDatePicker msg ->
            let
                ( startDatePicker, startDatePickerFx, mdate ) =
                    DatePicker.update msg model.startDatePicker

                ( startDate, endDate, endDatePicker, endDatePickerFx ) =
                    case mdate of
                        Nothing ->
                            ( model.startDate, model.endDate, model.endDatePicker, Cmd.none )

                        Just date ->
                            let
                                ( ed, dp, dpFx ) =
                                    initEndDatePicker date model.endDate
                            in
                                ( date, ed, dp, dpFx )
            in
                prepareTimes
                    { model
                        | startDate = startDate
                        , startDatePicker = startDatePicker
                        , endDate = endDate
                        , endDatePicker = endDatePicker
                    }
                    ! [ Cmd.map ToStartDatePicker startDatePickerFx
                      , Cmd.map ToEndDatePicker endDatePickerFx
                      ]

        ToEndDatePicker msg ->
            let
                ( endDatePicker, endDatePickerFx, mdate ) =
                    DatePicker.update msg model.endDatePicker
            in
                prepareTimes
                    { model
                        | endDate = mdate ?> endDate
                        , endDatePicker = endDatePicker
                    }
                    ! [ Cmd.map ToEndDatePicker endDatePickerFx
                      ]

        ToStartTimePicker msg ->
            let
                ( startTimePicker, mtime ) =
                    TimePicker.update msg model.startTimePicker
            in
                prepareTimes
                    { model
                        | startTime = mtime ?> startTime
                        , startTimePicker = startTimePicker
                    }
                    ! []

        ToEndTimePicker msg ->
            let
                ( endTimePicker, mtime ) =
                    TimePicker.update msg model.endTimePicker
            in
                { model
                    | endTime = mtime ?> endTime
                    , endTimePicker = endTimePicker
                }
                    ! []

        CheckAll checked ->
            let
                filterSubset u =
                    if isOffline model u then
                        Nothing
                    else
                        Just u.email
            in
                case model.attendeeState of
                    None ->
                        { model
                            | attendeeState = Subset
                            , attendees = Set.fromList <| List.filterMap filterSubset model.teamMembers
                        }
                            ! []

                    Subset ->
                        { model
                            | attendeeState = All
                            , attendees = Set.fromList <| List.map .email model.teamMembers
                        }
                            ! []

                    All ->
                        { model
                            | attendeeState = None
                            , attendees = Set.empty
                        }
                            ! []

        Check email checked ->
            let
                attendees =
                    if checked then
                        Set.insert email model.attendees
                    else
                        Set.remove email model.attendees
            in
                { model
                    | attendeeState =
                        if Set.isEmpty attendees then
                            None
                        else
                            Subset
                    , attendees = attendees
                }
                    ! []

        Submit ->
            model ! []


view : Model -> Html Msg
view ({ startDatePicker, startTimePicker, endDatePicker, endTimePicker, teamMembers, attendeeState } as model) =
    let
        check =
            checkbox "all" (attendeeState == All) (attendeeState == Subset) CheckAll
    in
        page "Meetings"
            [ FC.formWithAttrs Submit
                [ class "scheduler" ]
                [ div [ class "column" ]
                    [ heading "Schedule a meeting"
                    , div [ class "range" ]
                        [ Html.map ToStartDatePicker <| lazy DatePicker.view startDatePicker
                        , Html.map ToStartTimePicker <| lazy TimePicker.view startTimePicker
                        , span [] [ text "to" ]
                        , Html.map ToEndDatePicker <| lazy DatePicker.view endDatePicker
                        , Html.map ToEndTimePicker <| lazy TimePicker.view endTimePicker
                        ]
                    , textarea [ class "description", placeholder "Description" ] []
                    , br [] []
                    , input
                        [ type' "submit"
                        , value "Schedule meeting"
                        ]
                        []
                    ]
                , div [ class "column" ]
                    [ heading "Attendees"
                    , table []
                        [ thead []
                            [ tr []
                                [ td [ style [ "width" => "30px" ] ] [ check ]
                                , td [ style [ "width" => "40%" ] ] [ text "Name" ]
                                , td [ style [] ] [ text "Available" ]
                                ]
                            ]
                        , tbody [] (List.map (memberRow model) teamMembers)
                        ]
                    ]
                ]
            ]


checkbox : String -> Bool -> Bool -> (Bool -> Msg) -> Html Msg
checkbox elId isChecked isIndeterminate msg =
    input
        [ type' "checkbox"
        , property "indeterminate" (Json.bool isIndeterminate)
        , checked isChecked
        , onCheck msg
        , id elId
        ]
        []


memberRow : Model -> User -> Html Msg
memberRow ({ attendees } as model) ({ fullName, email } as user) =
    let
        id =
            "checkbox--" ++ email

        offline =
            isOffline model user
    in
        tr [ classList [ "offline" => offline ] ]
            [ td [] [ checkbox id (email `Set.member` attendees) False (Check email) ]
            , td [] [ label [ for id ] [ text fullName ] ]
            , td [] [ text <| yn <| not offline ]
            ]


yn : Bool -> String
yn x =
    if x then
        "Yes"
    else
        "No"


isOffline : Model -> User -> Bool
isOffline { startDate, startTime, endDate, endTime } user =
    let
        startTimestamp =
            mkTimestamp startDate startTime

        endTimestamp =
            mkTimestamp endDate endTime
    in
        User.isOffline startTimestamp user || User.isOffline endTimestamp user


mkTimestamp : Date -> Time -> Timestamp
mkTimestamp date time =
    Date.toTime date + Time.toMillis time


prepareTimes : Model -> Model
prepareTimes ({ startDate, startTime, endDate, endTime } as model) =
    let
        st =
            if datesEq startDate endDate && Time.compare startTime endTime == GT then
                startTime
            else
                Time.zero

        ( et, tp ) =
            initEndTimePicker st endTime
    in
        { model
            | endTime = et
            , endTimePicker = tp
        }


initEndDatePicker : Date -> Date -> ( Date, DatePicker, Cmd DatePicker.Msg )
initEndDatePicker startDate endDate =
    let
        isDisabled d =
            dateTuple d < dateTuple startDate

        endDate' =
            if isDisabled endDate then
                startDate
            else
                endDate

        ( dp, dpFx ) =
            DatePicker.init
                { defaultSettings
                    | isDisabled = isDisabled
                    , pickedDate = Just endDate'
                }
    in
        ( endDate', dp, dpFx )


initEndTimePicker : Time -> Time -> ( Time, TimePicker.Model )
initEndTimePicker startTime endTime =
    let
        et =
            if Time.compare startTime endTime == GT then
                startTime
            else
                endTime
    in
        ( et, TimePicker.initWithMin startTime et )


datesEq : Date -> Date -> Bool
datesEq a b =
    dateTuple a == dateTuple b


anchorTo : AnchorTo Msg
anchorTo =
    Util.anchorTo RouteTo
