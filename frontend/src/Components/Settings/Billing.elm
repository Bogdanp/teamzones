module Components.Settings.Billing exposing (Model, Msg, init, update, view)

import Api exposing (Error, Response)
import Api.Billing as Billing exposing (SubscriptionStatus(..), Subscription)
import Components.ConfirmationButton as CB
import Components.Loading exposing (loading)
import Components.Notifications exposing (error)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App as Html
import Task
import Timestamp


type Msg
    = SubscriptionError Error
    | SubscriptionSuccess (Response Subscription)
    | CancelSubscriptionError Error
    | CancelSubscriptionSuccess (Response String)
    | ToCancelButton CB.Msg


type alias Model =
    { data : Maybe Subscription
    , cancelButton : CB.Model
    }


fetchSubscription : Cmd Msg
fetchSubscription =
    Task.perform SubscriptionError SubscriptionSuccess Billing.fetchSubscription


init : ( Model, Cmd Msg )
init =
    { data = Nothing, cancelButton = CB.init "Cancel your subscription" }
        ! [ fetchSubscription ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubscriptionError _ ->
            model ! [ error "We encountered an issue while trying to retrieve your billing information. Please try again later." ]

        SubscriptionSuccess { data } ->
            { model | data = Just data } ! []

        CancelSubscriptionError _ ->
            model ! [ error "We encountered an issue while trying to cancel your subscription. Please try again later." ]

        CancelSubscriptionSuccess _ ->
            { model | data = Nothing } ! [ fetchSubscription ]

        ToCancelButton ((CB.ToParent (CB.Confirm)) as msg) ->
            { model | data = Nothing, cancelButton = CB.update msg model.cancelButton }
                ! [ Task.perform CancelSubscriptionError CancelSubscriptionSuccess Billing.cancelSubscription ]

        ToCancelButton msg ->
            { model | cancelButton = CB.update msg model.cancelButton } ! []


view : Model -> Html Msg
view { data, cancelButton } =
    Maybe.map (subscription cancelButton) data
        |> Maybe.withDefault loading


subscription : CB.Model -> Subscription -> Html Msg
subscription cancelButton data =
    let
        nextDate _ =
            Timestamp.format "MMM DD, YYYY" data.validUntil
    in
        case data.status of
            Pending ->
                div [] [ p [] [ text "Your subscription is currently being processed. Please check back later." ] ]

            Active ->
                div []
                    [ p [] [ text ("You will next be billed on " ++ nextDate () ++ ".") ]
                    , div [ class "input-group" ]
                        [ div [ class "input" ]
                            [ CB.view cancelButton
                                |> Html.map ToCancelButton
                            ]
                        ]
                    ]

            PastDue ->
                div []
                    [ p [] [ text ("Your subscription is past due and will expire on " ++ nextDate () ++ ".") ]
                    ]

            Canceled ->
                div []
                    [ p [] [ text ("Your subscription has been canceled and is valid until " ++ nextDate () ++ ".") ]
                    ]
