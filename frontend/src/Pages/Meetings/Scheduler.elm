module Pages.Meetings.Scheduler exposing (Msg, Model, init, update, view)

import Api exposing (Error, Response)
import Api.Calendar exposing (Meeting, createMeeting)
import Components.Duration as Duration exposing (Duration)
import Components.Form as FC
import Components.Notifications exposing (apiError, error, info)
import Components.Page exposing (heading)
import Components.TimePicker as TimePicker
import Components.TimePicker.Time as Time exposing (Time)
import Date exposing (Date)
import DatePicker exposing (DatePicker, defaultSettings)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (on, onCheck, targetValue)
import Html.Lazy exposing (lazy)
import Json.Decode as Json
import Json.Encode as JE
import Set exposing (Set)
import Task
import Timestamp exposing (Timestamp)
import Types exposing (User)
import User exposing (isOffline)
import Util exposing ((=>), (?>), dateTuple)


type Msg
    = ToDatePicker DatePicker.Msg
    | ToTimePicker TimePicker.Msg
    | ToDuration Duration.Msg
    | ChangeSummary String
    | ChangeDescription String
    | CheckAll Bool
    | Check String Bool
    | Submit
    | CreateError Error
    | CreateSuccess (Response String)


type AttendeeState
    = None
    | Subset
    | All


type alias Context m =
    { m
        | now : Timestamp
        , currentUser : User
        , teamMembers : List User
    }


type alias Model =
    { currentUser : User
    , teamMembers : List User
    , date : Date
    , datePicker : DatePicker
    , time : Time
    , timePicker : TimePicker.Model
    , duration : Duration
    , durationPicker : Duration.Model
    , summary : String
    , description : String
    , attendeeState : AttendeeState
    , attendees : Set String
    }


init : Context m -> ( Model, Cmd Msg )
init { now, currentUser, teamMembers } =
    let
        isDisabled date =
            dateTuple date < dateTuple (Date.fromTime now)

        later =
            now - (toFloat <| floor now `rem` 600000) + 900000

        date =
            Date.fromTime later

        ( datePicker, datePickerFx ) =
            DatePicker.init { defaultSettings | isDisabled = isDisabled, pickedDate = Just date }

        time =
            Time.fromMillis later

        timePicker =
            TimePicker.init time

        duration =
            3600000

        durationPicker =
            Duration.init duration
    in
        { currentUser = currentUser
        , teamMembers = teamMembers
        , date = date
        , datePicker = datePicker
        , time = time
        , timePicker = timePicker
        , duration = duration
        , durationPicker = durationPicker
        , summary = ""
        , description = ""
        , attendeeState = None
        , attendees = Set.empty
        }
            ! [ Cmd.map ToDatePicker datePickerFx
              ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToDatePicker msg ->
            let
                ( datePicker, datePickerFx, mdate ) =
                    DatePicker.update msg model.datePicker
            in
                { model
                    | date = mdate ?> model.date
                    , datePicker = datePicker
                }
                    ! [ Cmd.map ToDatePicker datePickerFx ]

        ToTimePicker msg ->
            let
                ( timePicker, time ) =
                    TimePicker.update msg model.timePicker
            in
                { model
                    | time = time
                    , timePicker = timePicker
                }
                    ! []

        ToDuration msg ->
            let
                ( durationPicker, duration ) =
                    Duration.update msg model.durationPicker
            in
                { model
                    | duration = duration
                    , durationPicker = durationPicker
                }
                    ! []

        ChangeSummary summary ->
            { model | summary = summary } ! []

        ChangeDescription description ->
            { model | description = description } ! []

        CheckAll checked ->
            let
                filterSubset u =
                    if isOffline (toTimestamp model) u then
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
            if Set.isEmpty model.attendees then
                model ! [ error "You must pick at least one attendee!" ]
            else
                model
                    ! [ meetingFromModel model
                            |> createMeeting
                            |> Task.perform CreateError CreateSuccess
                      ]

        CreateError err ->
            model ! apiError err

        CreateSuccess _ ->
            model ! [ info "Your meeting has been scheduled." ]


view : Model -> Html Msg
view ({ teamMembers, datePicker, timePicker, durationPicker, attendeeState } as model) =
    let
        check =
            checkbox "all" (attendeeState == All) (attendeeState == Subset) CheckAll
    in
        FC.formWithAttrs Submit
            [ class "scheduler" ]
            [ div [ class "column" ]
                [ heading "Schedule a meeting"
                , div [ class "range" ]
                    [ Html.map ToDatePicker <| lazy DatePicker.view datePicker
                    , Html.map ToTimePicker <| lazy TimePicker.view timePicker
                    , Html.map ToDuration <| lazy Duration.view durationPicker
                    ]
                , input
                    [ class "input summary"
                    , type' "text"
                    , placeholder "Summary"
                    , on "change" (Json.map ChangeSummary targetValue)
                    ]
                    []
                , textarea
                    [ class "input description"
                    , placeholder "Description"
                    , on "change" (Json.map ChangeDescription targetValue)
                    ]
                    []
                , br [] []
                , input
                    [ class "button"
                    , type' "submit"
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


checkbox : String -> Bool -> Bool -> (Bool -> Msg) -> Html Msg
checkbox elId isChecked isIndeterminate msg =
    input
        [ type' "checkbox"
        , property "indeterminate" (JE.bool isIndeterminate)
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
            isOffline (toTimestamp model) user
    in
        tr [ classList [ "offline" => offline ] ]
            [ td [] [ checkbox id (email `Set.member` attendees) False (Check email) ]
            , td [] [ label [ for id ] [ text fullName ] ]
            , td [] [ text <| yesNo <| not offline ]
            ]


toTimestamp : Model -> Timestamp
toTimestamp { date, time } =
    let
        ( year, month, day ) =
            dateTuple date

        ( h, m, p ) =
            time

        ( hour, minute ) =
            if p == Time.PM then
                ( h `rem` 12 + 12, m )
            else
                ( h `rem` 12, m )

        num n =
            if n < 10 then
                "0" ++ toString n
            else
                toString n
    in
        toString year
            ++ "-"
            ++ num month
            ++ "-"
            ++ num day
            ++ "T"
            ++ num hour
            ++ ":"
            ++ num minute
            ++ ":00"
            |> Timestamp.fromString


yesNo : Bool -> String
yesNo x =
    if x then
        "Yes"
    else
        "No"


meetingFromModel : Model -> Meeting
meetingFromModel ({ duration, summary, description, attendees } as model) =
    let
        startTime =
            toTimestamp model

        endTime =
            startTime + duration
    in
        { id = ""
        , startTime = startTime
        , endTime = endTime
        , summary = summary
        , description = description
        , attendees = Set.toList attendees
        }
