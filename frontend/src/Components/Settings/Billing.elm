module Components.Settings.Billing exposing (Model, Msg, init, update, view)

import Api exposing (Error, Response)
import Api.Billing as Billing exposing (BillingCycle(..), SubscriptionStatus(..), Subscription, SubscriptionPlan)
import Components.ConfirmationButton as CB
import Components.Form as FC
import Components.Loading exposing (loading)
import Components.Notifications exposing (info, error)
import Dict exposing (Dict)
import Form exposing (Form)
import Form.Field exposing (Field(..))
import Form.Validate as Validate exposing (Validation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App as Html
import Task
import Timestamp
import Util exposing ((=>))


type Msg
    = SubscriptionError Error
    | SubscriptionSuccess (Response Subscription)
    | CancelSubscriptionError Error
    | CancelSubscriptionSuccess (Response String)
    | ActivatePlanError Error
    | ActivatePlanSuccess (Response String)
    | UpdateVatIdError Error
    | UpdateVatIdSuccess (Response String)
    | UpdateVatId
    | ToCancelButton CB.Msg
    | ToActivateButton String CB.Msg
    | ToVatForm Form.Msg


type alias Model =
    { data : Maybe Subscription
    , vatPending : Bool
    , vatForm : Form () String
    , cancelButton : CB.Model
    , activateButtons : Dict String CB.Model
    }


fetchSubscription : Cmd Msg
fetchSubscription =
    Task.perform SubscriptionError SubscriptionSuccess Billing.fetchSubscription


validateVatForm : Validation () String
validateVatForm =
    (Validate.get "vat-id" <| Validate.oneOf [ Validate.emptyString, Validate.string ])


init : ( Model, Cmd Msg )
init =
    { data = Nothing
    , vatPending = False
    , vatForm = Form.initial [] validateVatForm
    , cancelButton = CB.init "Cancel your subscription"
    , activateButtons = Dict.empty
    }
        ! [ fetchSubscription ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubscriptionError e ->
            model ! [ error "We encountered an issue while trying to retrieve your billing information. Please try again later." ]

        SubscriptionSuccess { data } ->
            let
                buttons =
                    List.foldl (\p -> Dict.insert p.id (CB.init "Activate")) Dict.empty data.plans

                vatForm =
                    Form.initial [ "vat-id" => Text data.vatId ] validateVatForm
            in
                { model
                    | data = Just data
                    , activateButtons = buttons
                    , vatPending = False
                    , vatForm = vatForm
                }
                    ! []

        CancelSubscriptionError _ ->
            model ! [ error "We encountered an issue while trying to cancel your subscription. Please try again later." ]

        CancelSubscriptionSuccess _ ->
            { model | data = Nothing } ! [ fetchSubscription ]

        ActivatePlanError _ ->
            model
                ! [ error "We encountered an issue while trying to change your subscription. Please contact support."
                  , fetchSubscription
                  ]

        ActivatePlanSuccess _ ->
            model ! [ fetchSubscription ]

        UpdateVatIdError _ ->
            model
                ! [ error "We encountered an issue while trying to update your VAT id. Please contact support. "
                  ]

        UpdateVatIdSuccess _ ->
            { model | data = Nothing }
                ! [ info "Your VAT id has been saved successfully and your subscription has been updated accordingly."
                  , fetchSubscription
                  ]

        UpdateVatId ->
            let
                form =
                    Form.update Form.Submit model.vatForm

                vatId =
                    Form.getOutput form
            in
                case vatId of
                    Nothing ->
                        { model | vatForm = form } ! []

                    Just vatId ->
                        { model | vatPending = True, vatForm = form }
                            ! [ Billing.updateVatId vatId
                                    |> Task.perform UpdateVatIdError UpdateVatIdSuccess
                              ]

        ToCancelButton ((CB.ToParent (CB.Confirm)) as msg) ->
            { model | data = Nothing, cancelButton = CB.update msg model.cancelButton }
                ! [ Task.perform CancelSubscriptionError CancelSubscriptionSuccess Billing.cancelSubscription ]

        ToCancelButton msg ->
            { model | cancelButton = CB.update msg model.cancelButton } ! []

        ToActivateButton id ((CB.ToParent (CB.Confirm)) as msg) ->
            let
                buttons =
                    Dict.update id (Maybe.map (CB.update msg)) model.activateButtons
            in
                { model | data = Nothing, activateButtons = buttons }
                    ! [ Billing.updatePlan id
                            |> Task.perform ActivatePlanError ActivatePlanSuccess
                      ]

        ToActivateButton id msg ->
            let
                buttons =
                    Dict.update id (Maybe.map (CB.update msg)) model.activateButtons
            in
                { model | activateButtons = buttons } ! []

        ToVatForm msg ->
            { model | vatForm = Form.update msg model.vatForm } ! []


view : Model -> Html Msg
view { data, vatPending, vatForm, cancelButton, activateButtons } =
    case data of
        Nothing ->
            loading

        Just data ->
            let
                plan =
                    lookupPlan data data.planId
            in
                div []
                    [ overview data plan cancelButton
                    , plans data plan activateButtons
                    , if data.vat /= 0 then
                        vat data vatPending vatForm
                      else
                        text ""
                    ]


overview : Subscription -> SubscriptionPlan -> CB.Model -> Html Msg
overview data plan cancelButton =
    table [ class "billing-overview" ]
        [ thead []
            [ tr []
                [ td [ colspan 2 ] [ text "Billing Overview" ]
                ]
            ]
        , case data.status of
            Pending ->
                pendingOverview data plan

            Active ->
                activeOverview data plan cancelButton

            PastDue ->
                pastDueOverview data plan cancelButton

            Canceled ->
                canceledOverview data plan
        ]


row : String -> List (Html Msg) -> Html Msg
row label content =
    tr []
        [ td [] [ text label ]
        , td [] content
        ]


pendingOverview : Subscription -> SubscriptionPlan -> Html Msg
pendingOverview data plan =
    tbody []
        [ row "Plan" [ strong [] [ text <| label plan ] ]
        , row "Status"
            [ strong [] [ text "Pending" ]
            , br [] []
            , text "Your subscription is currently being processed. Please check back later."
            ]
        ]


activeOverview : Subscription -> SubscriptionPlan -> CB.Model -> Html Msg
activeOverview data plan cancelButton =
    tbody []
        [ row "Plan" [ strong [] [ text <| label plan ] ]
        , row "Payment amount" [ text <| amount data plan ]
        , row "Next payment due" [ text <| nextDate data ]
        , row ""
            [ div [ class "input-group" ]
                [ div [ class "input" ]
                    [ CB.view cancelButton
                        |> Html.map ToCancelButton
                    ]
                ]
            ]
        ]


pastDueOverview : Subscription -> SubscriptionPlan -> CB.Model -> Html Msg
pastDueOverview data plan cancelButton =
    tbody []
        [ row "Plan" [ strong [] [ text <| label plan ] ]
        , row "Status"
            [ strong [] [ text "Past due" ]
            , br [] []
            , text "Your subscription is past due and will expire soon."
            ]
        , row "Valid until"
            [ text <| nextDate data ]
        ]


canceledOverview : Subscription -> SubscriptionPlan -> Html Msg
canceledOverview data plan =
    tbody []
        [ row "Plan" [ strong [] [ text <| label plan ] ]
        , row "Status"
            [ strong [] [ text "Canceled" ]
            , br [] []
            , text "Your subscription has been canceled and will expire soon."
            ]
        , row "Valid until"
            [ text <| nextDate data ]
        ]


vat : Subscription -> Bool -> Form () String -> Html Msg
vat ({ vat, vatId } as data) pending form =
    let
        textInput' label name =
            let
                options =
                    FC.defaultOptions name
            in
                Html.map ToVatForm (FC.textInput { options | label = Just label } form)
    in
        div []
            [ FC.form UpdateVatId
                [ h4 [] [ text "VAT information" ]
                , textInput' "VAT ID" "vat-id"
                , FC.submitWithOptions { label = "Update VAT Id", disabled = pending }
                ]
            , if vatId == "" then
                p [] [ text "If you’re a registered business, enter your VAT identification number to remove VAT from your bill." ]
              else
                text ""
            ]


plans : Subscription -> SubscriptionPlan -> Dict String CB.Model -> Html Msg
plans ({ plans } as data) plan buttons =
    let
        button p =
            case Dict.get p.id buttons of
                Nothing ->
                    Debug.crash ("activateButton not found: " ++ p.id)

                Just b ->
                    b

        planRow p =
            let
                current =
                    p.id == plan.id
            in
                tr []
                    [ td []
                        [ if current then
                            strong [] [ text p.label ]
                          else
                            text p.label
                        ]
                    , td [] [ text p.summary ]
                    , td [] [ text <| amount data p ]
                    , td []
                        [ if current then
                            text ""
                          else
                            CB.view (button p) |> Html.map (ToActivateButton p.id)
                        ]
                    ]
    in
        div []
            [ h4 [] [ text "Change plan" ]
            , table []
                [ thead []
                    [ tr []
                        [ td [ style [ "width" => "20%" ] ] [ text "Plan" ]
                        , td [ style [ "width" => "35%" ] ] [ text "Summary" ]
                        , td [ style [ "width" => "25%" ] ] [ text "Price" ]
                        , td [ style [ "width" => "20%" ] ] []
                        ]
                    ]
                , tbody []
                    (List.map planRow plans)
                ]
            ]


lookupPlan : Subscription -> String -> SubscriptionPlan
lookupPlan data planId =
    case List.filter ((==) planId << .id) data.plans |> List.head of
        Nothing ->
            Debug.crash ("lookupPlan: plan not found: " ++ planId)

        Just p ->
            p


label : SubscriptionPlan -> String
label p =
    case p.billingCycle of
        Month ->
            p.label ++ " Monthly"

        Year ->
            p.label ++ " Yearly"

        _ ->
            p.label


amount : Subscription -> SubscriptionPlan -> String
amount data p =
    let
        price =
            if data.needVat then
                p.monthlyPrice + floor (toFloat p.monthlyPrice * (toFloat data.vat / 100))
            else
                p.monthlyPrice

        dollars =
            toString <| price // 100

        cents =
            let
                x =
                    price `rem` 100
            in
                if x < 10 then
                    "0" ++ toString x
                else
                    toString x

        amount =
            "$"
                ++ dollars
                ++ "."
                ++ cents
                ++ "/mo"
                ++ if data.needVat then
                    " (incl. VAT)"
                   else
                    ""
    in
        case p.billingCycle of
            Month ->
                amount ++ " billed monthly"

            Year ->
                amount ++ " billed yearly"

            _ ->
                amount


nextDate : Subscription -> String
nextDate data =
    Timestamp.format "YYYY-MM-DD" data.validUntil
